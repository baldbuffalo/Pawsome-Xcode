import SwiftUI
import Firebase
import FirebaseFirestore

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
                    PostsListView()
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
    
    private func PostsListView() -> some View {
        List {
            ForEach(viewModel.posts) { post in
                PostCardView(post: post)  // Ensure PostCardView exists
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
