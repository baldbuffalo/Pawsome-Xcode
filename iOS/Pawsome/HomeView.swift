import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct HomeView: View {
    @EnvironmentObject var appState: PawsomeApp.AppState
    @Binding var isLoggedIn: Bool
    @Binding var currentUsername: String
    @Binding var profileImageURL: String?
    @Binding var activeFlow: PawsomeApp.HomeFlow?

    @State private var posts: [Post] = []
    @State private var isLoading = true
    @State private var selectedFilter: PostStatus?
    @State private var listener: ListenerRegistration?
    @State private var selectedPostForComments: Post?

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    FilterButton(title: "All 🐾", selected: selectedFilter == nil) { selectedFilter = nil }
                    ForEach(PostStatus.allCases) { status in
                        FilterButton(title: "\(status.emoji) \(status.displayName)", selected: selectedFilter == status) {
                            selectedFilter = selectedFilter == status ? nil : status
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }

            Button { activeFlow = .form } label: {
                Label("Create a new post", systemImage: "plus")
                    .font(.headline.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 52)
            }
            .buttonStyle(.borderedProminent)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 16)

            Spacer(minLength: 8)

            let filteredPosts = selectedFilter == nil ? posts : posts.filter { $0.status == selectedFilter }
            if isLoading && posts.isEmpty {
                Spacer()
                ProgressView()
                Spacer()
            } else if filteredPosts.isEmpty {
                Spacer()
                VStack(spacing: 10) {
                    Text("😿").font(.system(size: 64))
                    Text("No cats found").font(.title3.bold())
                    Text("Be the first to post!").foregroundStyle(.secondary)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredPosts) { post in
                            CatPostView(
                                post: post,
                                onLike: { toggleLike(post: post) },
                                onComment: { selectedPostForComments = post },
                                onDelete: post.userID == appState.currentUserID ? { Task { await deletePost(post) } } : nil
                            )
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.vertical, 16)
                }
            }
        }
        .background(Color(uiColor: .systemBackground))
        .onAppear { startListening() }
        .onDisappear { listener?.remove() }
        .sheet(item: $selectedPostForComments) { CommentsView(post: $0) }
    }

    private func startListening() {
        isLoading = true
        listener?.remove()
        listener = Firestore.firestore().collection("posts")
            .order(by: "PostedAt", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error { print("❌", error.localizedDescription); isLoading = false; return }
                posts = snapshot?.documents.compactMap { Post(id: $0.documentID, data: $0.data()) } ?? []
                isLoading = false
            }
    }

    private func toggleLike(post: Post) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let ref = Firestore.firestore().collection("posts").document(post.id)
        if post.likes.contains(uid) {
            ref.updateData(["likes": FieldValue.arrayRemove([uid])])
        } else {
            ref.updateData(["likes": FieldValue.arrayUnion([uid])])
        }
    }

    private func deletePost(_ post: Post) async {
        if let filename = post.imageURL.components(separatedBy: "/").last, !filename.isEmpty {
            try? await GitHubUploader.shared.deleteFile(path: "postImages/\(filename)")
        }
        try? await Firestore.firestore().collection("posts").document(post.id).delete()
    }
}

private struct FilterButton: View {
    let title: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 14)
                .frame(minHeight: 36)
        }
        .buttonStyle(.bordered)
        .tint(selected ? .purple : .secondary)
        .background(selected ? Color.purple : Color.clear, in: Capsule())
        .foregroundStyle(selected ? .white : .primary)
    }
}
