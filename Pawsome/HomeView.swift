import SwiftUI
import Firebase
import FirebaseFirestore
import CatPostModule  // Ensure this module provides the CatPost model

struct HomeView: View {
    @State private var posts: [CatPost] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var postToDelete: CatPost?

    private let db = Firestore.firestore()

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading posts...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if posts.isEmpty {
                    EmptyStateView()
                } else {
                    PostsListView(posts: posts)
                }
            }
            .navigationTitle("Pawsome")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
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

    // MARK: - Fetch Posts
    private func fetchPosts() {
        isLoading = true
        db.collection("posts").order(by: "timestamp", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    errorMessage = "Failed to load posts: \(error.localizedDescription)"
                } else {
                    posts = snapshot?.documents.compactMap { doc in
                        let data = doc.data()

                        // Map the comments array to the Comment model instead of [String]
                        let commentsData = data["comments"] as? [[String: Any]] ?? []
                        let comments = commentsData.compactMap { commentData in
                            Comment(document: commentData)
                        }

                        return CatPost(
                            id: doc.documentID,
                            catName: data["catName"] as? String ?? "Unknown",
                            catBreed: data["catBreed"] as? String,
                            location: data["location"] as? String,
                            imageURL: data["imageURL"] as? String,
                            likes: data["likes"] as? Int ?? 0,
                            comments: comments // Use the array of Comment
                        )
                    } ?? []
                }
                isLoading = false
            }
    }

    // MARK: - Delete Post
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

    // MARK: - Subviews
    private func PostsListView(posts: [CatPost]) -> some View {
        List {
            ForEach(posts) { post in
                PostCardView(post: post)
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

    private func DeleteButton(post: CatPost) -> some View {
        Button(role: .destructive) {
            postToDelete = post
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
}

// MARK: - PostCardView
struct PostCardView: View {
    let post: CatPost

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(post.catName)
                .font(.headline)

            if let breed = post.catBreed, !breed.isEmpty {
                Text(breed)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            if let location = post.location, !location.isEmpty {
                Text(location)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            if let imageURL = post.imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { image in
                    image.resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 200)
                        .cornerRadius(10)
                } placeholder: {
                    ProgressView()
                }
            }

            HStack {
                Text("\(post.likes) Likes")
                    .font(.subheadline)
                Spacer()
                Text("\(post.comments.count) Comments")
                    .font(.subheadline)
            }
        }
        .padding()
        .background(Color(PlatformColor.backgroundColor)) // ✅ Fixed Background Issue
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// MARK: - EmptyStateView
struct EmptyStateView: View {
    var body: some View {
        VStack {
            Image(systemName: "square.stack.3d.up.slash")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.gray)
            Text("No posts available.")
                .font(.title)
                .foregroundColor(.gray)
                .padding()
        }
    }
}

// MARK: - Platform Compatibility
#if canImport(UIKit)
import UIKit
typealias PlatformColor = UIColor
extension PlatformColor {
    static var backgroundColor: UIColor { UIColor.systemBackground }
}
#elseif canImport(AppKit)
import AppKit
typealias PlatformColor = NSColor
extension PlatformColor {
    static var backgroundColor: NSColor { NSColor.windowBackgroundColor } // ✅ Equivalent for macOS
}
#endif
