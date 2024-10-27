import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CatPost.timestamp, ascending: false)],
        animation: .default)
    private var posts: FetchedResults<CatPost>

    @State private var capturedImage: UIImage? = nil
    @State private var videoURL: URL? = nil
    @State private var newPostContent: String = "" // New post content
    @State private var isPostButtonDisabled: Bool = true // Disable button initially
    var currentUsername: String // This should come from the profile tab
    @Binding var profileImage: Image? // Ensure this is a Binding

    var body: some View {
        NavigationStack {
            VStack {
                // Form fields for new post
                VStack(alignment: .leading) {
                    TextField("What's on your mind?", text: $newPostContent)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.bottom, 8)
                    
                    Button(action: {
                        addPost()
                    }) {
                        Text("Post")
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(isPostButtonDisabled ? Color.gray : Color.blue)
                            .cornerRadius(8)
                    }
                    .disabled(isPostButtonDisabled) // Disable button if fields are empty
                }
                .padding()

                // Display a message if no posts are available
                if posts.isEmpty {
                    Text("No posts yet! Start by creating a new one.")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    // List to display CatPosts
                    List {
                        ForEach(posts) { post in
                            VStack(alignment: .leading) {
                                HStack {
                                    Text("Posted by \(post.username ?? currentUsername)") // Use currentUsername
                                        .font(.headline)
                                        .foregroundColor(.blue)
                                    Spacer()
                                    // Menu for Edit and Delete options
                                    Menu {
                                        Button(action: {
                                            // Handle Edit action using objectID directly
                                            print("Edit post with ObjectID: \(post.objectID)") // Use objectID
                                        }) {
                                            Text("Edit")
                                        }
                                        Button(action: {
                                            // Handle Delete action
                                            deletePost(post: post)
                                        }) {
                                            Text("Delete")
                                                .foregroundColor(.red)
                                        }
                                    } label: {
                                        Image(systemName: "ellipsis")
                                            .foregroundColor(.blue)
                                            .padding(8)
                                            .background(Circle().fill(Color.gray.opacity(0.2)))
                                    }
                                }

                                // Displaying image or video
                                if let imageData = post.imageData, let uiImage = UIImage(data: imageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 200)
                                        .cornerRadius(10)
                                        .padding(.top)
                                } else if let videoURLString = post.videoURL, let videoURL = URL(string: videoURLString) {
                                    VideoPlayerView(videoURL: videoURL)
                                        .frame(height: 200)
                                        .cornerRadius(10)
                                        .padding(.top)
                                } else {
                                    Text("No media available.")
                                        .foregroundColor(.gray)
                                        .padding(.top)
                                }

                                // Display the user's input (new post content) under the media
                                Text(post.content ?? "No content")
                                    .font(.subheadline)
                                    .padding(.top, 5)
                                    .foregroundColor(.black) // Customize color as needed
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }

                Spacer()
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline) // Optional: For a cleaner title display
            .onChange(of: newPostContent) { newValue in
                // Enable post button if all fields are filled
                isPostButtonDisabled = newPostContent.isEmpty
            }
        }
    }

    // Function to add a new post
    private func addPost() {
        let newPost = CatPost(context: viewContext)
        newPost.timestamp = Date()
        newPost.username = currentUsername // Set the username from the profile
        newPost.content = newPostContent // Assuming you have a content attribute in CatPost

        saveContext()

        // Clear fields after posting
        newPostContent = ""
    }

    // Function to delete posts
    private func deletePosts(offsets: IndexSet) {
        withAnimation {
            offsets.map { posts[$0] }.forEach(viewContext.delete)
            saveContext()
        }
    }

    private func deletePost(post: CatPost) {
        withAnimation {
            viewContext.delete(post)
            saveContext()
        }
    }

    // Function to save context changes to Core Data
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            print("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}

// Placeholder VideoPlayer view (you can use AVKit for actual video playback)
struct VideoPlayerView: View {
    let videoURL: URL

    var body: some View {
        Text("Video: \(videoURL.lastPathComponent)") // Replace with AVKit player if needed
            .frame(height: 200)
            .background(Color.black)
            .foregroundColor(.white)
            .cornerRadius(8)
    }
}
