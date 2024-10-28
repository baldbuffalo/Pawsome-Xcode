import SwiftUI
import CoreData

struct FormView: View {
    @Binding var showForm: Bool
    var currentUsername: String
    var onPostCreated: (CatPost) -> Void
    @Binding var selectedImage: UIImage? // Binding to hold the selected image

    @Environment(\.managedObjectContext) private var viewContext

    // Properties for your CatPost
    @State private var catName: String = ""
    @State private var catBreed: String = ""
    @State private var catAge: String = ""
    @State private var location: String = ""
    @State private var content: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Cat Details")) {
                    TextField("Cat Name", text: $catName)
                    TextField("Breed", text: $catBreed)
                    TextField("Age", text: $catAge)
                        .keyboardType(.numberPad) // Set the keyboard type to number pad
                    TextField("Location", text: $location)
                    TextField("Description", text: $content)
                }

                Section {
                    // Show selected image if available
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .cornerRadius(10)
                    }
                }

                Button(action: {
                    createPost()
                }) {
                    Text("Post")
                        .foregroundColor(.blue)
                }
            }
            .navigationTitle("Create Post")
            .background(Color.white) // Set background color for tap gesture
            .onTapGesture {
                // Dismiss the keyboard when tapping outside
                hideKeyboard()
            }
        }
    }

    private func createPost() {
        let newPost = CatPost(context: viewContext)
        newPost.username = currentUsername
        newPost.catName = catName
        newPost.catBreed = catBreed
        newPost.catAge = Int32(catAge) ?? 0
        newPost.location = location
        newPost.content = content
        newPost.timestamp = Date()

        // Convert selectedImage to Data if it exists
        if let image = selectedImage {
            newPost.imageData = image.pngData() // Store the image as PNG data
        }

        do {
            try viewContext.save()
            onPostCreated(newPost) // Trigger the closure with the new post
            showForm = false // Close the form
        } catch {
            print("Error saving post: \(error.localizedDescription)")
        }
    }
}

// Extension to hide the keyboard
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
