import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseFirestore
import FirebaseAuth

// MARK: - ProfileView
struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()

    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading || viewModel.isImageLoading {
                    ProgressView("Loading...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                } else {
                    if let urlString = viewModel.profileImage,
                       let url = URL(string: urlString),
                       let data = try? Data(contentsOf: url),
                       let platformImage = PlatformImage(data: data) {

                        #if os(macOS)
                        Image(nsImage: platformImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .shadow(radius: 10)
                        #else
                        Image(uiImage: platformImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .shadow(radius: 10)
                        #endif
                    } else {
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 100, height: 100)
                            .overlay(Text("No Image").foregroundColor(.white))
                    }

                    Text("Username: \(viewModel.username)")
                        .font(.title)
                        .padding()

                    Button("Change Profile Image") {
                        viewModel.isImagePickerPresented.toggle()
                    }
                    .padding()
                }
            }
            .sheet(isPresented: $viewModel.isImagePickerPresented) {
                ImagePickerView(selectedImage: $viewModel.selectedImage) { image in
                    if let selectedImage = image {
                        viewModel.uploadProfileImageToFirebase(image: selectedImage)
                    }
                }
            }
            .navigationTitle("Profile")
            .onAppear {
                viewModel.loadProfileData()
            }
        }
    }
}

// MARK: - ProfileViewModel
class ProfileViewModel: ObservableObject {
    @Published var selectedImage: PlatformImage?
    @Published var profileImage: String?
    @Published var isImagePickerPresented = false
    @Published var username: String = "Anonymous"
    @Published var isImageLoading: Bool = false
    @Published var isLoading: Bool = false

    func loadProfileData() {
        guard let userID = Auth.auth().currentUser?.uid else { return }

        isLoading = true

        let db = Firestore.firestore()
        let profileRef = db.collection("users").document(userID)

        profileRef.getDocument { document, error in
            DispatchQueue.main.async {
                if let document = document, document.exists, let data = document.data() {
                    self.username = data["username"] as? String ?? "Anonymous"
                    self.loadProfileImage(from: data)
                } else {
                    print("No profile found or error: \(error?.localizedDescription ?? "unknown error")")
                    self.isLoading = false
                }
            }
        }
    }

    // ✅ Dynamic member: loadProfileImage
    func loadProfileImage(from data: [String: Any]) {
        if let imageURL = data["profileImage"] as? String {
            self.profileImage = imageURL
        } else {
            self.profileImage = nil
        }
        self.isLoading = false
    }

    func uploadProfileImageToFirebase(image: PlatformImage) {
        let storageRef = Storage.storage().reference().child("profilePictures/\(UUID().uuidString).png")

        #if os(macOS)
        guard let imageData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: imageData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return
        }
        #else
        guard let pngData = image.pngData() else {
            return
        }
        #endif

        isImageLoading = true

        Task {
            do {
                _ = try await storageRef.putDataAsync(pngData)
                let downloadURL = try await storageRef.downloadURL()
                await MainActor.run {
                    self.saveProfileImageURLToFirestore(url: downloadURL)
                }
            } catch {
                print("Error uploading image: \(error.localizedDescription)")
                await MainActor.run {
                    isImageLoading = false
                }
            }
        }
    }

    func saveProfileImageURLToFirestore(url: URL) {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let profileRef = db.collection("users").document(userID)

        profileRef.setData([
            "profileImage": url.absoluteString
        ], merge: true) { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error saving image URL: \(error.localizedDescription)")
                } else {
                    self.profileImage = url.absoluteString
                }
                self.isImageLoading = false
            }
        }
    }
}
