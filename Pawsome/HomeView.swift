import SwiftUI
import FirebaseFirestore

struct HomeView: View {
    @Binding var isLoggedIn: Bool
    @Binding var currentUsername: String
    @Binding var profileImage: Any?

    @State private var posts: [CatPost] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var postToDelete: CatPost?

    private let db = Firestore.firestore()

    var onPostCreated: (() -> Void)? = nil // ✅ Added but does nothing

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading posts...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if posts.isEmpty {
                    Text("No posts available.")
                        .font(.title)
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List {
                        ForEach(posts) { post in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(post.catName)
                                    .font(.headline)
                                
                                if let breed = post.catBreed {
                                    Text("Breed: \(breed)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                if let location = post.location {
                                    Text("Location: \(location)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                if let imageURL = post.imageURL, let url = URL(string: imageURL) {
                                    AsyncImage(url: url) { image in
                                        image.resizable()
                                            .scaledToFit()
                                            .frame(maxWidth: .infinity, maxHeight: 200)
                                            .cornerRadius(8)
                                    } placeholder: {
                                        ProgressView()
                                    }
                                }
                                
                                HStack {
                                    Text("\(post.likes) Likes")
                                    Spacer()
                                    Text("\(post.comments.count) Comments")
                                }
                                .font(.footnote)
                                .foregroundColor(.gray)
                            }
                            .padding(.vertical, 8)
                            .swipeActions(edge: .trailing) {
                                DeleteButton(post: post)
                            }
                            .contextMenu {
                                DeleteButton(post: post)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Pawsome")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: fetchPosts) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .alert("Error", isPresented: Binding(
                get: { errorMessage != nil },
                set: { _ in errorMessage = nil }
            )) {
                Text(errorMessage ?? "Unknown error")
            }
            .confirmationDialog("Delete Post?", isPresented: Binding(
                get: { postToDelete != nil },
                set: { _ in postToDelete = nil }
            )) {
                if let post = postToDelete {
                    Button("Delete", role: .destructive) {
                        deletePost(post)
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
            .onAppear { fetchPosts() }
            .refreshable { fetchPosts() }
        }
    }

    private func fetchPosts() {
        isLoading = true
        db.collection("posts").order(by: "timestamp", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    errorMessage = "Failed to load posts: \(error.localizedDescription)"
                } else {
                    posts = snapshot?.documents.compactMap { doc in
                        let data = doc.data()
                        return CatPost(
                            id: doc.documentID,
                            catName: data["catName"] as? String ?? "Unknown",
                            catBreed: data["catBreed"] as? String,
                            location: data["location"] as? String,
                            imageURL: data["imageURL"] as? String,
                            likes: data["likes"] as? Int ?? 0,
                            comments: data["comments"] as? [Comment] ?? []
                        )
                    } ?? []
                }
                isLoading = false
            }
    }

    private func deletePost(_ post: CatPost) {
        guard let postID = post.id else { return }
        db.collection("posts").document(postID).delete { error in
            if let error = error {
                errorMessage = "Failed to delete post: \(error.localizedDescription)"
            } else {
                posts.removeAll { $0.id == postID }
            }
        }
    }

    private func DeleteButton(post: CatPost) -> some View {
        Button(role: .destructive) {
            postToDelete = post
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
}
