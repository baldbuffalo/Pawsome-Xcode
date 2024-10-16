import SwiftUI

struct FormView: View {
    @Binding var showForm: Bool
    var imageUI: UIImage?
    var onPostCreated: (CatPost) -> Void

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
                    // Create a new CatPost using the updated initializer
                    let newPost = CatPost(
                        name: catName,
                        breed: breed,
                        age: age,
                        imageData: imageUI?.jpegData(compressionQuality: 0.8),
                        username: "YourUsername" // Adjust this according to your actual logic
                    )
                    onPostCreated(newPost) // Call the closure to pass the new post
                    showForm = false // Dismiss the form
                }) {
                    Text("Post")
                        .frame(maxWidth: .infinity)
                }
                .disabled(catName.isEmpty || breed.isEmpty || age.isEmpty)
            }
            .navigationTitle("Create Post")
            .navigationBarItems(trailing: Button("Cancel") {
                showForm = false // Dismiss the form
            })
        }
    }
}
