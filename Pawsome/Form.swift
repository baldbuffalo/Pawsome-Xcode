import SwiftUI
import AVKit // Import AVKit for VideoPlayer

struct FormView: View {
    @Binding var showForm: Bool
    var imageUI: UIImage?
    var videoURL: URL?
    var username: String
    var onPostCreated: (CatPost) -> Void

    @State private var catName: String = ""
    @State private var breed: String = ""
    @State private var age: String = ""
    @State private var location: String = ""
    @State private var description: String = ""
    @State private var liked: Bool = false // State to track if the post is liked

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
                
                if let videoURL = videoURL {
                    Section(header: Text("Captured Video")) {
                        VideoPlayer(player: AVPlayer(url: videoURL))
                            .frame(height: 300)
                            .cornerRadius(12)
                            .onAppear() {
                                AVPlayer(url: videoURL).play()
                            }
                    }
                }

                Section(header: Text("Post Details")) {
                    TextField("Cat Name", text: $catName)
                    TextField("Breed", text: $breed)
                    TextField("Age", text: $age)
                        .keyboardType(.numberPad)
                    TextField("Location", text: $location)
                    TextField("Description", text: $description)
                }

                Text("Posted by: \(username)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding()

                Button(action: {
                    // Create a new CatPost using the updated initializer
                    let newPost = CatPost(
                        name: catName,
                        breed: breed,
                        age: age,
                        imageData: imageUI?.jpegData(compressionQuality: 0.8),
                        username: username,
                        location: location
                    )
                    onPostCreated(newPost) // Call the closure to pass the new post
                    showForm = false // Dismiss the form
                }) {
                    Text("Post")
                        .frame(maxWidth: .infinity)
                }
                .disabled(catName.isEmpty || breed.isEmpty || age.isEmpty || location.isEmpty || description.isEmpty)

                // Thumbs Up Button for liking the post
                Button(action: {
                    liked.toggle() // Toggle the liked state
                }) {
                    HStack {
                        Image(systemName: liked ? "hand.thumbsup.fill" : "hand.thumbsup") // Change based on liked state
                            .font(.title)
                            .foregroundColor(liked ? .blue : .gray) // Change color based on liked state
                        Text(liked ? "Liked" : "Like") // Change button text based on liked state
                            .font(.headline)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.gray, lineWidth: 1))
                }
            }
            .navigationTitle("Create Post")
            .navigationBarItems(trailing: Button("Cancel") {
                showForm = false // Dismiss the form
            })
        }
    }
}
