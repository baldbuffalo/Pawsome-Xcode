import SwiftUI
import Firebase

struct HomeView: View {
    @Binding var posts: [CatPost]  // Binding to the posts array
    @State private var isEditing: Bool = false
    @State private var selectedPost: CatPost? = nil
    @State private var isLoading: Bool = true  // For showing loading indicator while fetching posts

    var body: some View {
        NavigationStack {
            VStack {
                if isLoading {
                    ProgressView("Loading posts...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                } else {
                    List($posts) { $post in
                        VStack(alignment: .leading) {
                            Text(post.catName)
                                .font(.headline)
                            Text(post.catBreed ?? "N/A")
                                .font(.subheadline)
                            Text("Age: \(post.catAge)")
                                .font(.subheadline)
                            
                            HStack {
                                Button("Edit") {
                                    selectedPost = post  // Set the selected post to edit
                                    isEditing = true
                                }
                                
                                Button("Delete") {
                                    deletePost(post)  // Delete the post from Firebase
                                }
                                
                                Button("Comment") {
                                    // Navigate to comments view
                                    // You can implement this according to your app's navigation logic
                                    // For example:
                                    // NavigationLink(destination: CommentsView(post: post)) {
                                    //     Text("View Comments")
                                    // }
                                }
                            }
                        }
                    }
                    .sheet(isPresented: $isEditing) {
                        if let selectedPost = selectedPost {
                            EditPostView(post: $selectedPost, isEditing: $isEditing)
                        }
                    }
                }
            }
            .onAppear {
                fetchPostsFromFirebase()  // Fetch posts when the view appears
            }
            .navigationTitle("Pawsome")
        }
    }

    private func fetchPostsFromFirebase() {
        let db = Firestore.firestore()

        // Correct Firestore API usage: Using getDocuments method with completion handler
        db.collection("posts").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching posts: \(error.localizedDescription)")
                isLoading = false
                return
            }

            // Safely unwrap the snapshot and map it into your post objects
            posts = snapshot?.documents.compactMap { document in
                let data = document.data()
                return CatPost(
                    id: document.documentID,
                    catName: data["catName"] as? String ?? "Unknown",
                    catBreed: data["catBreed"] as? String,
                    catAge: data["catAge"] as? Int32 ?? 0,
                    location: data["location"] as? String,
                    postDescription: data["postDescription"] as? String,
                    imageData: data["imageData"] as? Data,
                    likes: data["likes"] as? Int32 ?? 0,
                    username: data["username"] as? String ?? "Unknown",
                    comments: (data["comments"] as? [[String: Any]])?.compactMap { commentData in
                        guard let id = commentData["id"] as? String,
                              let username = commentData["username"] as? String,
                              let content = commentData["content"] as? String,
                              let timestamp = commentData["timestamp"] as? Timestamp else {
                                  return nil
                              }
                        return Comment(id: id, username: username, content: content, timestamp: timestamp)
                    } ?? []
                )
            } ?? []
            
            isLoading = false
        }
    }

    private func deletePost(_ post: CatPost) {
        let db = Firestore.firestore()
        db.collection("posts").document(post.id).delete { error in
            if let error = error {
                print("Error deleting post: \(error.localizedDescription)")
            } else {
                print("Post deleted successfully")
                if let index = posts.firstIndex(where: { $0.id == post.id }) {
                    posts.remove(at: index)  // Remove from local array
                }
            }
        }
    }
}
