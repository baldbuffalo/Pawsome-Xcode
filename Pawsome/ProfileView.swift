import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseFirestore
import FirebaseAuth
import Foundation

// MARK: - ViewModel

class ProfileViewModel: ObservableObject {
    @Published var selectedImage: PlatformImage? // Cross-platform image
    @Published var profileImage: String? // Firebase URL string
    @Published var isImagePickerPresented = false
    @Published var username: String = "Anonymous"
    @Published var isImageLoading: Bool = false
    @Published var isLoading: Bool = false
    @Published var isSaving: Bool = false

    func loadProfileData() {
        guard let userID = Auth.auth().currentUser?.uid else { return }

        isLoading = true
        let db = Firestore.firestore()
        let profileRef = db.collection("users").document(userID)

        profileRef.getDocument { document, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let document = document, document.exists, let data = document.data() {
                    self.username = data["username"] as? String ?? "Anonymous"
                    self.loadProfileImage(from: data)
                } else {
                    print("No profile found or error: \(error?.localizedDescription ?? "unknown error")")
                }
            }
        }
    }

    func loadProfileImage(from data: [String: Any]) {
        self.profileImage = data["profileImage"] as? String
    }

    func uploadProfileImageToFirebase(image: PlatformImage) {
        let storageRef = Storage.storage().reference().child("profilePictures/\(UUID().uuidString).png")
        var imageData: Data?

        #if os(iOS)
        imageData = image.pngData()
        #elseif os(macOS)
        if let tiffData = image.tiffRepresentation {
            imageData = NSBitmapImageRep(data: tiffData)?.representation(using: .png, properties: [:])
        }
        #endif

        guard let data = imageData else {
            print("Failed to get image data.")
            return
        }

        isImageLoading = true

        Task {
            do {
                _ = try await storageRef.putDataAsync(data)
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

        profileRef.setData(["profileImage": url.absoluteString], merge: true) { error in
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

    func saveUsernameToFirestore() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        isSaving = true

        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userID)

        userRef.setData(["username": self.username], merge: true) { error in
            DispatchQueue.main.async {
                self.isSaving = false
                if let error = error {
                    print("❌ Error saving username: \(error.localizedDescription)")
                } else {
                    print("✅ Username updated.")
                }
            }
        }
    }
}

// MARK: - View

struct ProfileView: View {
    @Binding var isLoggedIn: Bool
    @Binding var currentUsername: String
    @Binding var profileImage: String?

    @StateObject private var viewModel = ProfileViewModel()
    @FocusState private var usernameFocused: Bool

    var body: some View {
        VStack(spacing: 16) {
            if viewModel.isLoading {
                ProgressView("Loading Profile...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
            } else {
                Group {
                    if let imageUrlString = viewModel.profileImage ?? profileImage,
                       let imageUrl = URL(string: imageUrlString) {
                        AsyncImage(url: imageUrl) { phase in
                            switch phase {
                            case .empty: ProgressView()
                            case .success(let image):
                                image.resizable()
                                    .scaledToFit()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                            case .failure:
                                Image(systemName: "person.crop.circle.badge.exclamationmark")
                                    .resizable()
                                    .frame(width: 120, height: 120)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else {
                        Image(systemName: "person.crop.circle")
                            .resizable()
                            .frame(width: 120, height: 120)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.top)

                TextField("Username", text: $viewModel.username)
                    .font(.title2)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($usernameFocused)
                    .onChange(of: usernameFocused) { oldValue, newValue in
                        if oldValue == true && newValue == false {
                            viewModel.saveUsernameToFirestore()
                        }
                    }

                Text(viewModel.isSaving ? "Saving..." : "Saved")
                    .font(.caption)
                    .foregroundColor(viewModel.isSaving ? .gray : .green)

                Button(action: {
                    viewModel.isImagePickerPresented = true
                }) {
                    Label("Change Profile Picture", systemImage: "camera")
                }
                .padding()

                Spacer()
            }
        }
        .padding()
        .onAppear {
            viewModel.loadProfileData()
        }
        .sheet(isPresented: $viewModel.isImagePickerPresented) {
            ImagePickerView(selectedImage: $viewModel.selectedImage)
                .onDisappear {
                    if let image = viewModel.selectedImage {
                        viewModel.uploadProfileImageToFirebase(image: image)
                    }
                }
        }
    }
}
