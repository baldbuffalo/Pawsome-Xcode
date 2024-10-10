import SwiftUI

struct FormView: View {
    @Binding var showForm: Bool
    @Binding var catPosts: [CatPost] // Binding to the array of cat posts
    var imageUI: UIImage? // Captured image passed from ScanView

    @State private var catName: String = ""
    @State private var breed: String = ""
    @State private var age: String = ""
    @State private var comments: String = ""
    @State private var username: String = "YourUsername" // Placeholder for the logged-in username

    var body: some View {
        NavigationView {
            Form {
                if let image = imageUI {
                    Section(header: Text("Captured Image")) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 300)
                            .cornerRadius(12)
                    }
                }

                Section(header: Text("Post Details")) {
                    TextField("Cat Name", text: $catName)
                    TextField("Breed", text: $breed)
                    TextField("Age", text: $age)
                    TextField("Comments", text: $comments)
                    
                    // Display the username and make it read-only
                    TextField("Username", text: $username)
                        .disabled(true) // Assuming the username is fetched from the logged-in account
                }

                Button(action: {
                    savePost() // Save the post
                }) {
                    Text("Save Post")
                        .frame(maxWidth: .infinity)
                }
                .disabled(catName.isEmpty || breed.isEmpty || age.isEmpty) // Disable if fields are empty
            }
            .navigationTitle("Create Post")
            .navigationBarItems(trailing: Button("Cancel") {
                showForm = false
            })
        }
    }

    private func savePost() {
        guard let image = imageUI, !catName.isEmpty, !breed.isEmpty, !age.isEmpty else { return }

        // Convert the UIImage to Data
        let imageData = image.jpegData(compressionQuality: 1.0) // Convert UIImage to Data

        // Create a new CatPost instance
        let newPost = CatPost(
            id: UUID(),
            name: catName,
            breed: breed,
            age: age,
            imageData: imageData, // Store image data
            username: username,
            creationTime: Date(), // Set the creation time to now
            likes: 0,
            comments: [comments] // Save comments if needed
        )

        // Save the new post to the catPosts array
        catPosts.append(newPost)

        // Save posts to UserDefaults or any persistent storage
        savePosts() // Implement this function to persist posts

        // Dismiss the form after saving
        showForm = false
    }

    private func savePosts() {
        if let encodedData = try? JSONEncoder().encode(catPosts) {
            UserDefaults.standard.set(encodedData, forKey: "catPosts")
        }
    }
}
