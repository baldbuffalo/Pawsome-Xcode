import SwiftUI
import CoreData

struct HomeView: View {
    @Binding var isLoggedIn: Bool
    var currentUsername: String
    @Binding var profileImage: Image?

    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CatPost.timestamp, ascending: false)],
        animation: .default)
    private var posts: FetchedResults<CatPost>

    @State private var showScanView = false
    @State private var capturedImage: UIImage? = nil
    @State private var videoURL: URL? = nil

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
                    showScanView = true
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
                        addPost(newPost)
                    }
                }
            }
            .navigationTitle("Home")
        }
    }

    private func addPost(_ newPost: CatPost) {
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

// Placeholder VideoPlayer view
struct VideoPlayerView: View {
    let videoURL: URL

    var body: some View {
        Text("Video: \(videoURL.lastPathComponent)") // Replace with actual video player
            .frame(height: 200)
            .background(Color.black)
            .foregroundColor(.white)
            .cornerRadius(8)
    }
}
