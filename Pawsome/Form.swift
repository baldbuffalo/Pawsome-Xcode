import SwiftUI

// Assuming CatPost is defined in CatPost.swift
// Replace with your actual CatPost model import if necessary
// import your_module_name

struct FormView: View {
    @Binding var showForm: Bool // Binding to control the visibility of the form
    var imageUI: UIImage? // Captured image passed from ScanView
    var onPostCreated: (CatPost) -> Void // Closure to handle post creation

    @State private var catName: String = ""
    @State private var breed: String = ""
    @State private var age: String = ""
    @State private var comments: String = ""

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
                }

                Button(action: {
                    let newPost = CatPost(catName: catName, breed: breed, age: age, comments: comments, image: imageUI) // Create a new CatPost
                    onPostCreated(newPost) // Call the closure with the new post
                    showForm = false // Dismiss the form
                }) {
                    Text("Post")
                        .frame(maxWidth: .infinity)
                }
                .disabled(catName.isEmpty || breed.isEmpty || age.isEmpty) // Disable if fields are empty
            }
            .navigationTitle("Create Post")
            .navigationBarItems(trailing: Button("Cancel") {
                showForm = false // Dismiss the form
            })
        }
    }
}
