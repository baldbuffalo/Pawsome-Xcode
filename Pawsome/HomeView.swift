import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CatPost.timestamp, ascending: false)],
        animation: .default)
    private var posts: FetchedResults<CatPost>

    @State private var showScanView = false
    @State private var capturedImage: UIImage? = nil
    @State private var videoURL: URL? = nil
    var currentUsername: String
    @Binding var profileImage: Image? // Ensure this is a Binding

    var body: some View {
        NavigationStack {
            VStack {
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
                                Text("Posted by \(post.username ?? "Unknown")")
                                    .font(.headline)
                                    .foregroundColor(.blue)

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
                            }
                            .padding(.vertical, 8)
                        }
                        .onDelete(perform: deletePosts)
                    }
                }

                Spacer()

                // Button to add a new post
                Button(action: {
                    showScanView = true // Show ScanView when button is pressed
                }) {
                    Text("Add New Post")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(8)
                        .padding(.horizontal)
                }
                .sheet(isPresented: $showScanView) {
                    // Pass capturedImage and videoURL to ScanView
                    ScanView(capturedImage: $capturedImage, videoURL: $videoURL, username: currentUsername) { newPost in
                        addPost(newPost) // Pass the new CatPost
                    }
                }
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline) // Optional: For a cleaner title display
        }
    }

    // Function to add a new post
    private func addPost(_ newPost: CatPost) {
        // Add new post to Core Data
        let post = CatPost(context: viewContext)
        post.timestamp = Date() // Set timestamp
        post.username = newPost.username // Assuming newPost has this property
        post.imageData = newPost.imageData // Assuming imageData is of type Data
        post.videoURL = newPost.videoURL // Assuming videoURL is of type String

        saveContext()
    }

    // Function to delete posts
    private func deletePosts(offsets: IndexSet) {
        withAnimation {
            offsets.map { posts[$0] }.forEach(viewContext.delete)
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
