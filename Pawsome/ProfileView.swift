import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseFirestore
import FirebaseAuth

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()

    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isImageLoading {
                    ProgressView("Loading...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                } else {
                    if let urlString = viewModel.profileImage,
                       let url = URL(string: urlString),
                       let image = PlatformImage(contentsOf: url) {
                        
                        #if os(macOS)
                        Image(nsImage: image) // Use nsImage for macOS
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .shadow(radius: 10)
                        #else
                        Image(uiImage: image) // Use uiImage for iOS
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
                    // Check if the image is not nil before uploading
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
    @Published var profileImage: String? // URL string to profile image
    @Published var isImagePickerPresented = false
    @Published var username: String = "Anonymous"
    @Published var isImageLoading: Bool = false

    // Load profile data from Firebase Firestore
    func loadProfileData() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let profileRef = db.collection("users").document(userID)

        profileRef.getDocument { document, error in
            if let document = document, document.exists, let data = document.data() {
                DispatchQueue.main.async {
                    self.profileImage = data["profileImage"] as? String
                    self.username = data["username"] as? String ?? "Anonymous"
                }
            } else {
                print("No profile found or error: \(error?.localizedDescription ?? "unknown error")")
            }
        }
    }

    // Upload selected profile image to Firebase Storage
    func uploadProfileImageToFirebase(image: PlatformImage) {
        let storageRef = Storage.storage().reference().child("profilePictures/\(UUID().uuidString).png")

        #if os(macOS)
        guard let imageData = image.tiffRepresentation,
              let bitmapImageRep = NSBitmapImageRep(data: imageData),
              let pngData = bitmapImageRep.representation(using: .png, properties: [:]) else {
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

    // Save the uploaded profile image URL to Firestore
    func saveProfileImageURLToFirestore(url: URL) {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let profileRef = db.collection("users").document(userID)

        profileRef.setData([
            "profileImage": url.absoluteString
        ], merge: true) { error in
            if let error = error {
                print("Error saving profile image URL: \(error.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    self.profileImage = url.absoluteString
                    self.isImageLoading = false
                }
            }
        }
    }
}
