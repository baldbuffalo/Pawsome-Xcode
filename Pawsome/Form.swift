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
                    let newPost = CatPost(catName: catName, breed: breed, age: age, comments: comments, image: imageUI)
                    onPostCreated(newPost)
                    showForm = false
                }) {
                    Text("Post")
                        .frame(maxWidth: .infinity)
                }
                .disabled(catName.isEmpty || breed.isEmpty || age.isEmpty)
            }
            .navigationTitle("Create Post")
            .navigationBarItems(trailing: Button("Cancel") {
                showForm = false
            })
        }
    }
}
