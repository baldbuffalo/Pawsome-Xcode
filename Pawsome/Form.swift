import SwiftUI
<<<<<<< HEAD

struct FormView: View {
    @Binding var showForm: Bool
    @Binding var navigateToHome: Bool // Binding to control navigation
    var imageUI: UIImage?
    var videoURL: URL? // Keeping this for future use, but won't be displayed
    var username: String
    var onPostCreated: (CatPost) -> Void

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

                TextField("Cat Name", text: $catName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                TextField("Breed", text: $breed)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                TextField("Age", text: $age)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                TextField("Location", text: $location)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                TextField("Description", text: $description)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button(action: {
                    let catPost = CatPost(
                        username: username, // Correct order for initialization
                        name: catName,
                        breed: breed,
                        age: age,
                        location: location,
                        description: description,
                        imageData: imageUI?.pngData() // Move this to the end
                    )
                    onPostCreated(catPost)
                    showForm = false
                    navigateToHome = true // Navigate to HomeView
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
            // Dismiss the keyboard when tapping outside the text fields
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}
=======
import CoreData

struct FormView: View {
    @Binding var showForm: Bool
    var currentUsername: String
    var onPostCreated: (CatPost) -> Void
    @Binding var selectedImage: UIImage?

    @Environment(\.managedObjectContext) private var viewContext

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
                        .keyboardType(.numberPad)
                    TextField("Location", text: $location)
                    TextField("Description", text: $content)
                }

                Section {
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
            .background(Color.white)
            .onTapGesture {
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

        if let image = selectedImage {
            newPost.imageData = image.pngData()
        }

        do {
            try viewContext.save()
            onPostCreated(newPost) // Notify HomeView about the new post
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
>>>>>>> 5eef0f8bd39986f9f45e071df446cc125709c1b6
