import SwiftUI
import FirebaseFirestore

// MARK: - HomeViewModel
class HomeViewModel: ObservableObject {
    @Published var posts: [CatPost] = []
    @Published var isLoading = true
    @Published var errorMessage: String?

    private let db = Firestore.firestore()

    func fetchPosts() {
        isLoading = true
        Task {
            do {
                let snapshot = try await db.collection("posts")
                    .order(by: "timestamp", descending: true)
                    .getDocuments()
                
                let fetchedPosts = snapshot.documents.compactMap { doc -> CatPost? in
                    CatPost.from(data: doc.data(), id: doc.documentID)
                }
                
                await MainActor.run {
                    self.posts = fetchedPosts
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load posts: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }

    func deletePost(_ post: CatPost) {
        guard let postID = post.id else { return }
        db.collection("posts").document(postID).delete { error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Failed to delete post: \(error.localizedDescription)"
                } else {
                    self.posts.removeAll { $0.id == postID }
                }
            }
        }
    }
}

// MARK: - HomeView
struct HomeView: View {
    @Binding var isLoggedIn: Bool
    @Binding var currentUsername: String
    @Binding var profileImage: String?

    @StateObject private var viewModel = HomeViewModel()
    @State private var postToDelete: CatPost?

    var onPostCreated: (() -> Void)? = nil

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Pawsome")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: viewModel.fetchPosts) {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
                .alert("Error", isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { _ in viewModel.errorMessage = nil }
                )) {
                    Text(viewModel.errorMessage ?? "Unknown error")
                }
                .confirmationDialog("Delete Post?", isPresented: Binding(
                    get: { postToDelete != nil },
                    set: { _ in postToDelete = nil }
                )) {
                    if let post = postToDelete {
                        Button("Delete", role: .destructive) {
                            viewModel.deletePost(post)
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                }
                .onAppear { viewModel.fetchPosts() }
                .refreshable { viewModel.fetchPosts() }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            ProgressView("Loading posts...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.posts.isEmpty {
            Text("No posts available.")
                .font(.title)
                .foregroundColor(.gray)
                .padding()
        } else {
            List(viewModel.posts) { post in
                PostCell(post: post)
                    .swipeActions(edge: .trailing) {
                        deleteButton(post: post)
                    }
                    .contextMenu { deleteButton(post: post) }
            }
            .listStyle(.plain)
        }
    }

    private func deleteButton(post: CatPost) -> some View {
        Button(role: .destructive) {
            postToDelete = post
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
}

// MARK: - PostCell
private struct PostCell: View {
    let post: CatPost

    var body: some View {
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
    }
}
