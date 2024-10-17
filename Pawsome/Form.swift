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
    @State private var isPostCreated: Bool = false // State to track if the post has been created
    @State private var newPost: CatPost? // Store the new post data
    @State private var likeCount: Int = 0 // State to track the number of likes
    @State private var player: AVPlayer? // Player for video

    var body: some View {
        ScrollView { // Make the entire view scrollable
            VStack {
                if isPostCreated, let post = newPost {
                    Section(header: Text("Your Post")) {
                        if let imageData = post.imageData, let image = UIImage(data: imageData) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 300)
                                .cornerRadius(12)
                        }

                        if let videoURL = videoURL {
                            VideoPlayer(player: player)
                                .frame(height: 300)
                                .cornerRadius(12)
                                .onAppear {
                                    player = AVPlayer(url: videoURL)
                                    player?.play()
                                }
                        }

                        Text("Cat Name: \(post.name)")
                        Text("Breed: \(post.breed)")
                        Text("Age: \(post.age)")
                        Text("Location: \(post.location)")
                        Text("Description: \(post.description)")

                        // Thumbs Up Button for liking the post
                        HStack {
                            Button(action: {
                                liked.toggle() // Toggle the liked state
                                likeCount += liked ? 1 : -1 // Increment or decrement the like count
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
                            Text("\(likeCount)") // Display the like count
                                .font(.headline)
                                .padding(.leading)
                        }
                    }
                    .padding() // Padding for post section
                } else {
                    // Show the form fields if the post hasn't been created
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
                            VideoPlayer(player: player)
                                .frame(height: 300)
                                .cornerRadius(12)
                                .onAppear {
                                    player = AVPlayer(url: videoURL)
                                    player?.play()
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

                    Button(action: {
                        // Create a new CatPost using the updated initializer
                        let post = CatPost(
                            name: catName,
                            breed: breed,
                            age: age,
                            imageData: imageUI?.jpegData(compressionQuality: 0.8),
                            username: username,
                            location: location,
                            description: description // Include description in the CatPost
                        )
                        newPost = post // Store the new post data
                        isPostCreated = true // Update state to indicate the post has been created
                        onPostCreated(post) // Call the closure to pass the new post
                    }) {
                        Text("Post")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(catName.isEmpty || breed.isEmpty || age.isEmpty || location.isEmpty || description.isEmpty)
                }
            }
            .padding() // Padding for form content
        }
        .navigationTitle("Create Post")
        .navigationBarItems(trailing: Button("Cancel") {
            showForm = false // Dismiss the form if needed
        })
    }
}
