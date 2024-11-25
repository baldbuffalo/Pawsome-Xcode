import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseFirestore
import FirebaseAuth

class ProfileView: ObservableObject {
    @Published var selectedImage: NSImage?
    @Published var profileImage: String? // URL to the profile image
    @Published var isImagePickerPresented = false
    @Published var username: String = "Anonymous" // User's display name

    func uploadProfileImageToFirebase(image: NSImage) async {
        let storageRef = Storage.storage().reference().child("profilePictures/\(UUID().uuidString).png")

        if let imageData = image.tiffRepresentation {
            let bitmapImageRep = NSBitmapImageRep(data: imageData)
            if let pngData = bitmapImageRep?.representation(using: .png, properties: [:]) {
                do {
                    let _ = try await storageRef.putDataAsync(pngData)
                    let downloadURL = try await storageRef.downloadURL()
                    saveProfileImageURLToFirestore(url: downloadURL)
                } catch {
                    print("Error uploading image: \(error.localizedDescription)")
                }
            }
        }
    }

    private func saveProfileImageURLToFirestore(url: URL) {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let profileRef = db.collection("users").document(userID)

        profileRef.setData([
            "profileImage": url.absoluteString
        ], merge: true) { error in
            if let error = error {
                print("Error saving profile image URL to Firestore: \(error.localizedDescription)")
            } else {
                print("Profile image URL successfully saved!")
                self.profileImage = url.absoluteString // Save locally
            }
        }
    }
}
