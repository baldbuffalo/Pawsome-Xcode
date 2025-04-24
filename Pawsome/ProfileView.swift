import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseFirestore
import FirebaseAuth
import Foundation

#if os(iOS)
import UIKit // Import UIKit to get UIImage for iOS
#endif

#if os(macOS)
import AppKit // Import AppKit to get NSImage for macOS
#endif

// MARK: - ViewModel
class ProfileViewModel: ObservableObject {
    @Published var selectedImage: PlatformImage? // Using PlatformImage to support both iOS and macOS
    @Published var profileImage: String? // Holds the image URL as a String
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

    func loadProfileImage(from data: [String: Any]) {
        if let imageURL = data["profileImage"] as? String {
            self.profileImage = imageURL
        } else {
            self.profileImage = nil // No image URL found, set to nil
        }
        self.isLoading = false
    }

    func uploadProfileImageToFirebase(image: PlatformImage) { // Accept PlatformImage for both platforms
        let storageRef = Storage.storage().reference().child("profilePictures/\(UUID().uuidString).png")

        var imageData: Data?

        // Handle both iOS and macOS images
        #if os(iOS)
        if let uiImage = image as? UIImage { // For iOS (UIImage)
            imageData = uiImage.pngData() // Convert UIImage to PNG data for iOS
        }
        #elseif os(macOS)
        if let nsImage = image as? NSImage { // For macOS (NSImage)
            guard let tiffData = nsImage.tiffRepresentation else {
                print("Failed to get TIFF data from NSImage.")
                return
            }
            imageData = tiffData // Use TIFF data for macOS
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

// MARK: - ProfileView
struct ProfileView: View {
    @Binding var isLoggedIn: Bool
    @Binding var currentUsername: String
    @Binding var profileImage: String? // Holds the profile image URL

    @StateObject private var viewModel = ProfileViewModel()

    var body: some View {
        VStack(spacing: 16) {
            if viewModel.isLoading {
                ProgressView("Loading Profile...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
            } else {
                Group {
                    // Use the profileImage directly, without optional unwrapping
                    if let imageUrlString = viewModel.profileImage ?? profileImage,
                       let imageUrl = URL(string: imageUrlString) {
                        AsyncImage(url: imageUrl) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                            case .success(let image):
                                image
                                    .resizable()
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

                Text(viewModel.username.isEmpty ? currentUsername : viewModel.username)
                    .font(.title)
                    .padding(.bottom)

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
