import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseFirestore
import FirebaseAuth // Add this import to use Firebase Authentication

struct ProfileView: View {
    @State private var selectedImage: NSImage?
    @State private var profileImage: Image?
    @State private var isImagePickerPresented = false

    var body: some View {
        VStack {
            // Display the selected image or a placeholder
            if let profileImage = profileImage {
                profileImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
            } else {
                Text("No Profile Image")
                    .frame(width: 150, height: 150)
                    .background(Color.gray)
            }
            
            // Button to pick an image
            Button("Select Profile Picture") {
                isImagePickerPresented.toggle()
            }
            
            // Save button to upload the image and save the URL to Firestore
            Button("Save") {
                if let selectedImage = selectedImage {
                    Task {
                        await uploadProfileImageToFirebase(image: selectedImage)
                    }
                }
            }
            .disabled(selectedImage == nil) // Disable the button if no image is selected
        }
        .sheet(isPresented: $isImagePickerPresented) {
            ImagePicker(selectedImage: $selectedImage, profileImage: $profileImage)
        }
    }
    
    // Function to upload the profile image to Firebase Storage
    private func uploadProfileImageToFirebase(image: NSImage) async {
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
        let db = Firestore.firestore()
        let userID = Auth.auth().currentUser?.uid ?? "unknownUserID"
        let profileRef = db.collection("profilepicture").document(userID)
        
        profileRef.setData([
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

// Image Picker for macOS (Custom View for Picking an Image)
struct ImagePicker: View {
    @Binding var selectedImage: NSImage?
    @Binding var profileImage: Image?
    
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            Text("Select a Profile Picture")
                .font(.headline)
                .padding()

            // Button to choose an image
            Button("Choose Image") {
                pickImage()
            }

            // Display selected image preview
            if let selectedImage = selectedImage {
                Image(nsImage: selectedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
            }

            // Close the picker
            Button("Close") {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    // Function to show the image picker and handle the image selection
    private func pickImage() {
        let dialog = NSOpenPanel()
        dialog.allowedFileTypes = ["png", "jpg", "jpeg"]
        dialog.allowsMultipleSelection = false
        
        if dialog.runModal() == .OK, let url = dialog.url {
            if let image = NSImage(contentsOf: url) {
                selectedImage = image
                profileImage = Image(nsImage: image)
            }
        }
    }
}
