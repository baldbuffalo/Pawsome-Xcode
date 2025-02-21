import SwiftUI
import Firebase
import FirebaseFirestore
import CatPostModule  // Ensure this module provides the CatPost model

struct HomeView: View {
    @State private var posts: [CatPost] = []
    @State private var isLoading = true
    @State private var error: Error?
    @State private var selectedPost: CatPost?
    @State private var postToDelete: CatPost?
    @State private var showError = false
    
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
            .alert("Error", isPresented: $showError, presenting: error) { _ in } message: {
                Text($0.localizedDescription)
            }
            .confirmationDialog("Delete Post", isPresented: Binding(
                get: { postToDelete != nil },
                set: { _ in postToDelete = nil }
            )) {
                DeleteConfirmationButtons()
            }
            .sheet(item: $selectedPost) { post in
                EditPostView(post: post) { updatedPost in
                    updatePost(updatedPost)
                }
            }
            .refreshable { fetchPosts() }
            .onAppear { fetchPosts() }
        }
    }
    
    // MARK: - Firestore Methods
    
    private func fetchPosts() {
        isLoading = true
        Firestore.firestore().collection("posts").getDocuments { snapshot, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.error = error
                    self.showError = true
                } else {
                    self.posts = snapshot?.documents.compactMap { doc in
                        try? doc.data(as: CatPost.self)
                    } ?? []
                }
                self.isLoading = false
            }
        }
    }
    
    private func deletePost(_ post: CatPost) {
        guard let id = post.id else { return }
        Firestore.firestore().collection("posts").document(id).delete { error in
            DispatchQueue.main.async {
                if let error = error {
                    self.error = error
                    self.showError = true
                } else {
                    self.posts.removeAll { $0.id == post.id }
                }
            }
        }
    }

    // MARK: - Subviews

    private func PostsListView(posts: [CatPost]) -> some View {
        List {
            ForEach(posts) { post in
                PostCardView(post: post)
                    .swipeActions(edge: .trailing) {
                        SwipeDeleteButton(post: post)
                        SwipeEditButton(post: post)
                    }
                    .contextMenu {
                        EditButton(post: post)
                        DeleteButton(post: post)
                    }
            }
        }
        .listStyle(.plain)
    }
    
    private func SwipeDeleteButton(post: CatPost) -> some View {
        Button(role: .destructive) {
            postToDelete = post
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
    
    private func SwipeEditButton(post: CatPost) -> some View {
        Button {
            selectedPost = post
        } label: {
            Label("Edit", systemImage: "pencil")
        }
        .tint(.blue)
    }
    
    private func DeleteButton(post: CatPost) -> some View {
        Button(role: .destructive) {
            postToDelete = post
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
    
    private func DeleteConfirmationButtons() -> some View {
        Group {
            Button("Delete", role: .destructive) {
                if let post = postToDelete {
                    deletePost(post)
                }
            }
            Button("Cancel", role: .cancel) { }
        }
    }
}

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
            
            HStack {
                Text("\(post.likes) Likes")
                    .font(.subheadline)
                Spacer()
                Text("\(post.comments.count) Comments")
                    .font(.subheadline)
            }
        }
        .padding()
        .background(
            Color(
                #if os(iOS)
                UIColor.systemBackground
                #elseif os(macOS)
                NSColor.windowBackgroundColor
                #endif
            )
        )
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

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
