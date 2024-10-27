import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CatPost.timestamp, ascending: false)],
        animation: .default)
    private var posts: FetchedResults<CatPost> // Fetch results from Core Data

    @State private var showScanView = false // Controls presentation of ScanView
    @State private var capturedImage: UIImage? = nil // Holds the captured image
    @State private var videoURL: URL? = nil // Holds the captured video URL
    private var currentUsername: String = "User123" // Replace with actual username

    var body: some View {
        NavigationStack {
            VStack {
                if posts.isEmpty {
                    Text("No posts yet! Start by creating a new one.")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List {
                        ForEach(posts) { post in
                            VStack(alignment: .leading) {
                                Text("Posted by \(post.username ?? "Unknown")")
                                    .font(.headline)
                                    .foregroundColor(.blue)

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
                    ScanView(capturedImage: $capturedImage, videoURL: $videoURL, username: currentUsername) { newPost in
                        addPost(newPost) // Pass the new CatPost
                    }
                }
            }
            .navigationTitle("Home")
        }
    }

    private func addPost(_ newPost: CatPost) {
        // Use the passed newPost object directly
        saveContext()
    }

    private func deletePosts(offsets: IndexSet) {
        withAnimation {
            offsets.map { posts[$0] }.forEach(viewContext.delete)
            saveContext()
        }
    }

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
