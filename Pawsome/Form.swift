import SwiftUI
import CoreData

struct FormView: View {
    @Binding var showForm: Bool
    @Binding var navigateToHome: Bool
    var imageUI: UIImage?
    var videoURL: URL?
    var username: String
    var onPostCreated: (CatPost) -> Void // Make sure this is referring to the correct CatPost

    @Environment(\.managedObjectContext) private var viewContext

    @State private var catName: String = ""
    @State private var breed: String = ""
    @State private var age: String = ""
    @State private var location: String = ""
    @State private var description: String = ""
    @State private var comments: String = ""

    var body: some View {
        ScrollView {
            VStack {
                if let image = imageUI {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                } else {
                    Text("No image captured.")
                        .foregroundColor(.gray)
                }

                // Commented out the display of video URL
                /*
                if let videoURL = videoURL {
                    Text("Video URL: \(videoURL.absoluteString)")
                        .padding()
                }
                */

                // Create text fields for user input
                inputField(placeholder: "Cat Name", text: $catName)
                inputField(placeholder: "Breed", text: $breed)
                inputField(placeholder: "Age", text: $age, keyboardType: .numberPad)
                inputField(placeholder: "Location", text: $location)
                inputField(placeholder: "Description", text: $description)

                // Post Button
                Button(action: {
                    createPost()
                }) {
                    Text("Post")
                        .foregroundColor(catName.isEmpty || breed.isEmpty || age.isEmpty || location.isEmpty || description.isEmpty ? .gray : .blue)
                }
                .disabled(catName.isEmpty || breed.isEmpty || age.isEmpty || location.isEmpty || description.isEmpty)
                .padding()
            }
            .padding()
        }
        .onTapGesture {
            hideKeyboard()
        }
    }

    private func createPost() {
        // Ensure you're using the correct CatPost context
        let newPost = CatPost(context: viewContext)
        newPost.username = username
        newPost.catName = catName
        newPost.catBreed = breed
        newPost.catAge = Int32(age) ?? 0
        newPost.location = location
        newPost.content = description
        newPost.timestamp = Date()

        if let image = imageUI {
            newPost.imageData = image.pngData()
        }

        do {
            try viewContext.save()
            onPostCreated(newPost)
            showForm = false
            navigateToHome = true
        } catch {
            print("Error saving post: \(error.localizedDescription)")
        }
    }
}

// Helper function to create text fields
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
