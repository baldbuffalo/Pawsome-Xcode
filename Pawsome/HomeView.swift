import SwiftUI
import Firebase

struct HomeView: View {
    @Binding var posts: [CatPost]  // Binding to the posts array
    @State private var isEditing: Bool = false
    @State private var selectedPost: CatPost? = nil
    @State private var isLoading: Bool = true  // Loading state

    var body: some View {
        NavigationStack {
            VStack {
                if isLoading {
                    ProgressView("Loading posts...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                } else {
                    List {
                        ForEach($posts, id: \.id) { $post in
                            VStack(alignment: .leading) {
                                Text(post.catName)
                                    .font(.headline)
                                Text(post.catBreed ?? "Unknown Breed")
                                    .font(.subheadline)
                                Text("Age: \(post.catAge)")
                                    .font(.subheadline)

                                HStack {
                                    Button("Edit") {
                                        selectedPost = post
                                        isEditing = true
                                    }

                                    Button("Delete") {
                                        deletePost(post)
                                    }

                                    NavigationLink(destination: CommentsView(post: post)) {
                                        Text("View Comments")
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .onAppear {
                fetchPostsFromFirebase()
            }
            .sheet(isPresented: $isEditing) {
                if let selectedPost = selectedPost {
                    EditPostView(post: Binding(
                        get: { selectedPost },
                        set: { updatedPost in
                            if let index = posts.firstIndex(where: { $0.id == updatedPost.id }) {
                                posts[index] = updatedPost
                            }
                            selectedPost = nil
                            isEditing = false
                        }
                    ))
                }
            }
            .navigationTitle("Pawsome")
        }
    }

    private func fetchPostsFromFirebase() {
        let db = Firestore.firestore()
        isLoading = true

        db.collection("posts").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching posts: \(error.localizedDescription)")
                isLoading = false
                return
            }

            posts = snapshot?.documents.compactMap { document in
                let data = document.data()
                return CatPost(
                    id: document.documentID,
                    catName: data["catName"] as? String ?? "Unknown",
                    catBreed: data["catBreed"] as? String,
                    catAge: data["catAge"] as? Int ?? 0,
                    location: data["location"] as? String,
                    postDescription: data["postDescription"] as? String,
                    imageData: data["imageData"] as? Data,
                    likes: data["likes"] as? Int ?? 0,
                    username: data["username"] as? String ?? "Unknown",
                    comments: [] // Adjust this based on how you load comments in CommentsView
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
                    posts.remove(at: index)
                }
            }
        }
    }
}
