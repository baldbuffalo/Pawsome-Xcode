import SwiftUI

struct FormView: View {
    @Binding var showForm: Bool
    var imageUI: UIImage
    var username: String
    var onPostCreated: (CatPost) -> Void // Closure to handle the post creation

    @State private var catName: String = ""
    @State private var breed: String = ""
    @State private var age: String = ""
    @State private var comments: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Post Details")) {
                    TextField("Cat Name", text: $catName)
                    TextField("Breed", text: $breed)
                    TextField("Age", text: $age)
                    TextField("Comments", text: $comments)
                }

                Section {
                    Button(action: {
                        let post = CatPost(
                            name: catName,
                            breed: breed,
                            age: age,
                            imageData: imageUI.jpegData(compressionQuality: 0.8),
                            username: username,
                            comments: comments.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) } // Splitting comments by comma
                        )
                        onPostCreated(post) // Call the closure with the new post
                        showForm = false // Dismiss the form
                    }) {
                        Text("Post")
                            .foregroundColor(catName.isEmpty || breed.isEmpty || age.isEmpty ? .gray : .blue)
                            .disabled(catName.isEmpty || breed.isEmpty || age.isEmpty) // Disable if any field is empty
                    }
                }
            }
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
