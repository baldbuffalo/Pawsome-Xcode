import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseFirestore
import FirebaseAuth

// ProfileView acts as both the View and ViewModel here for simplicity
struct ProfileView: View {
    @State private var selectedImage: NSImage?
    @State private var profileImage: String? // URL to the profile image
    @State private var isImagePickerPresented = false
    @State private var username: String = "Anonymous" // User's display name
    
    @State private var isImageLoading: Bool = false // To track image loading state

    var body: some View {
        NavigationView {
            VStack {
                if isImageLoading {
                    ProgressView("Loading Profile Image...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                } else {
                    // Display profile image or placeholder
                    if let profileImageURL = profileImage, let url = URL(string: profileImageURL), let image = NSImage(contentsOf: url) {
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

                    Text("Username: \(username)")
                        .font(.title)
                        .padding()

                    Button("Change Profile Image") {
                        isImagePickerPresented.toggle()
                    }
                    .padding()
                }
            }
            .sheet(isPresented: $isImagePickerPresented) {
                ImagePickerView(selectedImage: $selectedImage, onImagePicked: { image in
                    uploadProfileImageToFirebase(image: image)
                })
            }
            .navigationTitle("Profile")  // Update this line for macOS
            .onAppear {
                loadProfileData()
            }
        }
    }

    // Load user profile data
    private func loadProfileData() {
        // Fetch profile image URL from Firestore (if it exists)
        if let userID = Auth.auth().currentUser?.uid {
            let db = Firestore.firestore()
            let profileRef = db.collection("users").document(userID)
            profileRef.getDocument { (document, error) in
                if let document = document, document.exists, let data = document.data() {
                    profileImage = data["profileImage"] as? String
                    username = data["username"] as? String ?? "Anonymous"
                } else {
                    print("No profile found")
                }
            }
        }
    }

    // Upload selected profile image to Firebase Storage
    private func uploadProfileImageToFirebase(image: NSImage) {
        let storageRef = Storage.storage().reference().child("profilePictures/\(UUID().uuidString).png")

        if let imageData = image.tiffRepresentation {
            let bitmapImageRep = NSBitmapImageRep(data: imageData)
            if let pngData = bitmapImageRep?.representation(using: .png, properties: [:]) {
                isImageLoading = true
                Task {
                    do {
                        let _ = try await storageRef.putDataAsync(pngData)
                        let downloadURL = try await storageRef.downloadURL()
                        saveProfileImageURLToFirestore(url: downloadURL)
                    } catch {
                        print("Error uploading image: \(error.localizedDescription)")
                        isImageLoading = false
                    }
                }
            }
        }
    }

    // Save profile image URL to Firestore
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
                profileImage = url.absoluteString // Save locally for immediate UI update
                isImageLoading = false
            }
        }
    }
}

struct ImagePickerView: View {
    @Binding var selectedImage: NSImage?
    var onImagePicked: (NSImage) -> Void

    var body: some View {
        VStack {
            // Custom image picker UI can be here (using FilePicker, ImagePicker libraries, etc.)
            // For now, we are just using a simple button for illustration.
            Button("Pick an image") {
                // Simulating image selection process
                if let image = NSImage(named: "exampleImage") {
                    selectedImage = image
                    onImagePicked(image)
                }
            }
            .padding()

            if let selectedImage = selectedImage {
                // Resize the image manually for macOS
                Image(nsImage: selectedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
            }
        }
    }
}
