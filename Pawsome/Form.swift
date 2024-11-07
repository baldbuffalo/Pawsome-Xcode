import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseStorage

struct FormView: View {
    @Binding var showForm: Bool
    @Binding var navigateToHome: Bool
    var imageUI: UIImage?
    var videoURL: URL?
    var username: String

    @State private var catName: String = ""
    @State private var breed: String = ""
    @State private var age: String = ""
    @State private var location: String = ""
    @State private var description: String = ""

    var body: some View {
        ScrollView {
            VStack {
                if let image = imageUI {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .cornerRadius(10)
                } else {
                    Text("No image captured.")
                        .foregroundColor(.gray)
                        .padding()
                }

                inputField(placeholder: "Cat Name", text: $catName)
                inputField(placeholder: "Breed", text: $breed)
                inputField(placeholder: "Age", text: $age, keyboardType: .numberPad)
                inputField(placeholder: "Location", text: $location)
                inputField(placeholder: "Description", text: $description)

                Button(action: {
                    createPost()
                }) {
                    Text("Post")
                        .foregroundColor(isFormComplete ? .blue : .gray)
                }
                .disabled(!isFormComplete)
                .padding()
            }
            .padding()
        }
        .onTapGesture {
            hideKeyboard()
        }
    }

    // Helper function to check if the form is complete
    private var isFormComplete: Bool {
        return !catName.isEmpty && !breed.isEmpty && !age.isEmpty && !location.isEmpty && !description.isEmpty
    }

    // Function to create a post and save it to Firebase
    private func createPost() {
        guard let ageValue = Int32(age) else { return }
        
        // Upload image to Firebase Storage (if available)
        if let image = imageUI {
            let imageData = image.pngData()
            let storageRef = Storage.storage().reference().child("cat_images/\(UUID().uuidString).png")
            
            storageRef.putData(imageData!, metadata: nil) { metadata, error in
                guard error == nil else {
                    print("Error uploading image: \(error!.localizedDescription)")
                    return
                }
                
                // Get the image URL after successful upload
                storageRef.downloadURL { url, error in
                    guard let downloadURL = url, error == nil else {
                        print("Error getting download URL: \(error!.localizedDescription)")
                        return
                    }
                    
                    // Create a post object with the data
                    let postData: [String: Any] = [
                        "username": username,
                        "catName": catName,
                        "catBreed": breed,
                        "catAge": ageValue,
                        "location": location,
                        "description": description,
                        "imageURL": downloadURL.absoluteString,
                        "timestamp": Timestamp(date: Date()) // Store the timestamp of the post
                    ]
                    
                    // Save to Firestore
                    Firestore.firestore().collection("posts").addDocument(data: postData) { error in
                        if let error = error {
                            print("Error saving post: \(error.localizedDescription)")
                        } else {
                            print("Post saved successfully!")
                            // Update the UI and navigate home
                            showForm = false
                            navigateToHome = true
                        }
                    }
                }
            }
        } else {
            // If no image, still create the post with text data only
            let postData: [String: Any] = [
                "username": username,
                "catName": catName,
                "catBreed": breed,
                "catAge": ageValue,
                "location": location,
                "description": description,
                "imageURL": "", // No image URL if no image is provided
                "timestamp": Timestamp(date: Date()) // Store the timestamp of the post
            ]
            
            // Save to Firestore
            Firestore.firestore().collection("posts").addDocument(data: postData) { error in
                if let error = error {
                    print("Error saving post: \(error.localizedDescription)")
                } else {
                    print("Post saved successfully!")
                    // Update the UI and navigate home
                    showForm = false
                    navigateToHome = true
                }
            }
        }
    }
}

// Helper function for text fields
private func inputField(placeholder: String, text: Binding<String>, keyboardType: UIKeyboardType = .default) -> some View {
    TextField(placeholder, text: text)
        .keyboardType(keyboardType)
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .padding()
}

// Extension to hide the keyboard
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
