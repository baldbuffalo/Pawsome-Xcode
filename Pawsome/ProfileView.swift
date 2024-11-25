import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseFirestore
import FirebaseAuth

class ProfileView: ObservableObject {
    @Published var selectedImage: NSImage?
    @Published var profileImage: Image?
    @Published var isImagePickerPresented = false
    @Published var username: String = "" // Add username property
    
    private let db = Firestore.firestore()
    private let userID = Auth.auth().currentUser?.uid ?? "unknownUserID"
    
    // Fetch user data from Firestore
    func fetchUserData() async {
        let userRef = db.collection("users").document(userID)
        do {
            let document = try await userRef.getDocument()
            if let data = document.data() {
                username = data["username"] as? String ?? "Unknown User"
            }
        } catch {
            print("Error fetching user data: \(error.localizedDescription)")
        }
    }
    
    // Function to upload the profile image to Firebase Storage
    func uploadProfileImageToFirebase(image: NSImage) async {
        let storageRef = Storage.storage().reference().child("profilePictures/\(UUID().uuidString).png")
        
        // Convert the NSImage to data
        if let imageData = image.tiffRepresentation {
            let bitmapImageRep = NSBitmapImageRep(data: imageData)
            if let pngData = bitmapImageRep?.representation(using: .png, properties: [:]) {
                do {
                    let _ = try await storageRef.putDataAsync(pngData)
                    let downloadURL = try await storageRef.downloadURL()
                    // Save the URL to Firestore
                    saveProfileImageURLToFirestore(url: downloadURL)
                } catch {
                    print("Error uploading image: \(error.localizedDescription)")
                }
            }
        }
    }

    // Function to save the profile image URL to Firestore
    private func saveProfileImageURLToFirestore(url: URL) {
        let profileRef = db.collection("users").document(userID)
        
        profileRef.updateData([
            "profilePictureURL": url.absoluteString
        ]) { error in
            if let error = error {
                print("Error saving profile image URL to Firestore: \(error.localizedDescription)")
            } else {
                print("Profile picture URL successfully saved!")
            }
        }
    }
}
