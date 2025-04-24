import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseAuth
import Foundation
import UniformTypeIdentifiers
import PhotosUI
import Combine

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()

    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView("Loading...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                } else {
                    if let image = viewModel.profileImage {
                        Image(platformImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .padding()
                    } else {
                        Text("No Profile Image")
                            .foregroundColor(.gray)
                            .padding()
                    }

                    Text(viewModel.username)
                        .font(.title)
                        .padding()

                    Button("Change Profile Image") {
                        viewModel.isImagePickerPresented = true
                    }
                    .padding()
                }
            }
            .sheet(isPresented: $viewModel.isImagePickerPresented) {
                ImagePickerView(selectedImage: $viewModel.selectedImage) { image in
                    viewModel.uploadProfileImageToFirebase(image: image)
                }
            }
            .navigationTitle("Profile")
            .onAppear {
                viewModel.loadProfileData()
            }
        }
    }
}

class ProfileViewModel: ObservableObject {
    @Published var isLoading: Bool = true
    @Published var selectedImage: PlatformImage?
    @Published var profileImage: PlatformImage?
    @Published var profileImageURL: String?
    @Published var isImagePickerPresented = false
    @Published var username: String = "Anonymous"
    @Published var isImageLoading: Bool = false

    func loadProfileData() {
        guard let userID = Auth.auth().currentUser?.uid else {
            self.isLoading = false
            return
        }

        let db = Firestore.firestore()
        let profileRef = db.collection("users").document(userID)

        profileRef.getDocument { document, error in
            if let document = document, document.exists, let data = document.data() {
                self.username = data["username"] as? String ?? "Anonymous"
                if let imageUrlString = data["profileImage"] as? String,
                   let imageURL = URL(string: imageUrlString) {
                    self.downloadImage(from: imageURL)
                } else {
                    DispatchQueue.main.async {
                        self.isLoading = false
                    }
                }
            } else {
                print("No profile found or error: \(error?.localizedDescription ?? "unknown error")")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }
    }

    private func downloadImage(from url: URL) {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let data = data {
                    #if os(macOS)
                    self.profileImage = NSImage(data: data)
                    #else
                    self.profileImage = UIImage(data: data)
                    #endif
                } else {
                    print("Failed to download image: \(error?.localizedDescription ?? "unknown error")")
                }
                self.isLoading = false
            }
        }
        task.resume()
    }

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
                    self.isImageLoading = false
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
            if let error = error {
                print("Error saving profile image URL: \(error.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    self.downloadImage(from: url)
                }
            }
        }
    }
}
