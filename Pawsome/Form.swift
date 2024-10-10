import SwiftUI

struct FormView: View {
    @Binding var showForm: Bool
    @Binding var catPosts: [CatPost] // Binding to the array of cat posts
    var imageUI: UIImage? // Captured image passed from ScanView

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
                    TextField("Username", text: $username)
                        .disabled(true) // Assuming the username is fetched from the logged-in account
                }

                Button(action: {
                    savePost() // Save the post
                }) {
                    Text("Save Post")
                }
            }
            .navigationTitle("Create Post")
            .navigationBarItems(trailing: Button("Cancel") {
                showForm = false
            })
        }
    }

    private func savePost() {
        guard let image = imageUI else { return }

        // Create a new CatPost instance
        let newPost = CatPost(username: username, image: image) // Pass the image directly to CatPost

        // Save the new post to the catPosts array
        catPosts.append(newPost)

        // You may want to handle saving the posts to a database or local storage here

        // Dismiss the form after saving
        showForm = false
    }
}
