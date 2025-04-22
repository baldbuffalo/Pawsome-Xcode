import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseFirestore
import FirebaseAuth

// ProfileView now conforms to ObservableObject
class ProfileView: ObservableObject {
    @Published var selectedImage: NSImage?
    @Published var profileImage: String? // URL to the profile image
    @Published var isImagePickerPresented = false
    @Published var username: String = "Anonymous" // User's display name
    @Published var isImageLoading: Bool = false // To track image loading state

    // The body is still the same but we'll change ProfileView to a class
    func loadProfileData() {
        // Fetch profile image URL from Firestore (if it exists)
        if let userID = Auth.auth().currentUser?.uid {
            let db = Firestore.firestore()
            let profileRef = db.collection("users").document(userID)
            profileRef.getDocument { (document, error) in
                if let document = document, document.exists, let data = document.data() {
                    self.profileImage = data["profileImage"] as? String
                    self.username = data["username"] as? String ?? "Anonymous"
                } else {
                    print("No profile found")
                }
            }
        }
    }

    // Upload selected profile image to Firebase Storage
    func uploadProfileImageToFirebase(image: NSImage) {
        let storageRef = Storage.storage().reference().child("profilePictures/\(UUID().uuidString).png")

        if let imageData = image.tiffRepresentation {
            let bitmapImageRep = NSBitmapImageRep(data: imageData)
            if let pngData = bitmapImageRep?.representation(using: .png, properties: [:]) {
                self.isImageLoading = true
                Task {
                    do {
                        let _ = try await storageRef.putDataAsync(pngData)
                        let downloadURL = try await storageRef.downloadURL()
                        self.saveProfileImageURLToFirestore(url: downloadURL)
                    } catch {
                        print("Error uploading image: \(error.localizedDescription)")
                        self.isImageLoading = false
                    }
                }
            }
        }
    }

    // Save profile image URL to Firestore
    func saveProfileImageURLToFirestore(url: URL) {
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
                self.profileImage = url.absoluteString // Save locally for immediate UI update
                self.isImageLoading = false
            }
        }
    }
}

struct ProfileViewUI: View {
    @StateObject var profileView = ProfileView() // Use ProfileView as a StateObject

    var body: some View {
        NavigationView {
            VStack {
                if profileView.isImageLoading {
                    ProgressView("Loading Profile Image...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                } else {
                    // Display profile image or placeholder
                    if let profileImageURL = profileView.profileImage, let url = URL(string: profileImageURL), let image = NSImage(contentsOf: url) {
                        // Resize the image manually for macOS
                        Image(nsImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .shadow(radius: 10)
                    } else {
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 100, height: 100)
                            .overlay(Text("No Image").foregroundColor(.white))
                    }

                    Text("Username: \(profileView.username)")
                        .font(.title)
                        .padding()

                    Button("Change Profile Image") {
                        profileView.isImagePickerPresented.toggle()
                    }
                    .padding()
                }
            }
            .sheet(isPresented: $profileView.isImagePickerPresented) {
                ImagePickerView(selectedImage: $profileView.selectedImage, onImagePicked: { image in
                    profileView.uploadProfileImageToFirebase(image: image)
                })
            }
            .navigationTitle("Profile")  // Update this line for macOS
            .onAppear {
                profileView.loadProfileData()
            }
        }
    }
}
