import SwiftUI
import Firebase
import FirebaseFirestore
import CatPostModule  // Ensure this module provides the CatPost model

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var selectedPost: CatPost?
    @State private var postToDelete: CatPost?
    @State private var showError = false
    @State private var isAddingPost = false
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading posts...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.posts.isEmpty {
                    EmptyStateView()
                } else {
                    PostsListView(posts: viewModel.posts)
                }
            }
            .navigationTitle("Pawsome")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isAddingPost = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .alert("Error", isPresented: $showError, presenting: viewModel.error) { _ in } message: {
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
                    viewModel.updatePost(updatedPost)
                }
            }
            .sheet(isPresented: $isAddingPost) {
                AddPostView { newPost in
                    viewModel.savePost(newPost)
                }
            }
            .refreshable { viewModel.fetchPosts() }
            .onAppear { viewModel.fetchPostsIfNeeded() }
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
    
    private func DeleteConfirmationButtons() -> some View {
        Group {
            Button("Delete", role: .destructive) {
                if let post = postToDelete {
                    viewModel.deletePost(post)
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
