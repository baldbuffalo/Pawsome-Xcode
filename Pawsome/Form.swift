import SwiftUI

struct FormView: View {
    @Binding var catPosts: [CatPost]
    @Binding var currentUsername: String // Pass username from HomeView
    @State private var catName = ""
    @State private var catBreed = ""
    @State private var catAge = ""
    @State private var catLocation = ""
    @State private var imageUI: UIImage? = nil
    @State private var isSubmitting = false
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Cat Details")) {
                    TextField("Cat Name", text: $catName)
                    TextField("Cat Breed", text: $catBreed)
                    TextField("Cat Age", text: $catAge)
                    TextField("Location", text: $catLocation)
                }

                Section(header: Text("Image")) {
                    if let image = imageUI {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                    } else {
                        Text("No Image Selected")
                    }
                }

                Button(action: {
                    submitForm()
                }) {
                    if isSubmitting {
                        ProgressView()
                    } else {
                        Text("Submit")
                    }
                }
                .disabled(isSubmitting)
            }
            .navigationTitle("Create Post")
        }
    }

    private func submitForm() {
        isSubmitting = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            let newPost = CatPost(
                id: UUID(),
                name: catName,
                breed: catBreed,
                age: catAge,
                location: catLocation,
                likes: 0,
                comments: [],
                image: imageUI,
                username: currentUsername, // Use the logged-in username
                creationTime: Date() // Use the current date and time
            )
            
            catPosts.insert(newPost, at: 0)
            savePosts()
            isSubmitting = false
            presentationMode.wrappedValue.dismiss()
        }
    }

    // Save the updated posts
    private func savePosts() {
        if let encodedData = try? JSONEncoder().encode(catPosts) {
            UserDefaults.standard.set(encodedData, forKey: "catPosts")
        }
    }
}
