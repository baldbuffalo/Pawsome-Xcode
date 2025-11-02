import SwiftUI

// MARK: - HomeViewModel (Local Version)
class HomeViewModel: ObservableObject {
    @Published var posts: [CatPost] = []
    @Published var isLoading = true
    @Published var errorMessage: String?

    init() {
        fetchPosts()
    }

    func fetchPosts() {
        isLoading = true
        // Simulate loading delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.posts = [
                CatPost(id: "1", catName: "Fluffy", catBreed: "Persian", location: "Dubai", imageURL: nil, postDescription: "Super cute!", likes: 5, comments: [], catAge: 2, username: "User1", timestamp: Date(), form: nil),
                CatPost(id: "2", catName: "Mittens", catBreed: "Siamese", location: "Abu Dhabi", imageURL: nil, postDescription: "Loves naps", likes: 3, comments: [], catAge: 1, username: "User2", timestamp: Date(), form: nil)
            ]
            self.isLoading = false
        }
    }

    func deletePost(_ post: CatPost) {
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            posts.remove(at: index)
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
