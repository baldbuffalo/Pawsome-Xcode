import SwiftUI

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
                        imageData: imageUI?.pngData(),
                        location: location,
                        description: description
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
