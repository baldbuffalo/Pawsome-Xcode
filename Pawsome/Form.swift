import SwiftUI

struct FormView: View {
    @Binding var showForm: Bool
    var imageUI: UIImage? // Optional UIImage for the captured image
    var videoURL: URL? // Optional URL for the captured video
    var username: String
    var onPostCreated: (CatPost) -> Void

    @State private var catName: String = ""
    @State private var breed: String = ""
    @State private var age: String = ""
    @State private var location: String = "" // New state for location
    @State private var description: String = "" // New state for description
    @State private var comments: String = ""

    var body: some View {
        ScrollView { // Wrap the content in a ScrollView
            VStack {
                if let image = imageUI {
                    // Display the captured image if it exists
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                } else {
                    Text("No image captured.")
                        .foregroundColor(.gray)
                }

                if let videoURL = videoURL {
                    // Display video URL if it exists
                    Text("Video URL: \(videoURL.absoluteString)")
                        .padding()
                }

                TextField("Cat Name", text: $catName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                TextField("Breed", text: $breed)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                TextField("Age", text: $age)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                TextField("Location", text: $location) // New field for location
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                TextField("Description", text: $description) // New field for description
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                TextField("Comments", text: $comments)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button(action: {
                    // Handle post creation
                    let catPost = CatPost(
                        name: catName, // Cat name
                        breed: breed, // Breed
                        age: age, // Age
                        imageData: imageUI?.pngData(), // Convert UIImage to Data
                        username: username, // Username
                        location: location, // Location
                        description: description // Description
                    )
                    onPostCreated(catPost)
                    showForm = false // Dismiss the form
                }) {
                    Text("Post")
                        .foregroundColor(catName.isEmpty || breed.isEmpty || age.isEmpty || location.isEmpty || description.isEmpty ? .gray : .blue)
                }
                .disabled(catName.isEmpty || breed.isEmpty || age.isEmpty || location.isEmpty || description.isEmpty) // Disable button if any fields are empty
                .padding()
            }
            .padding()
        }
    }
}
