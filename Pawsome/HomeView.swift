import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct HomeView: View {
    @Binding var isLoggedIn: Bool
    @Binding var currentUsername: String
    @Binding var profileImageURL: String?
    @Binding var activeFlow: PawsomeApp.HomeFlow?

    @State private var posts: [Post] = []
    @State private var isLoading = true
    @State private var listener: ListenerRegistration?
    @State private var selectedPostForComments: Post?

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.purple.opacity(0.18), Color.blue.opacity(0.18), Color.cyan.opacity(0.12)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                LazyVStack(spacing: 16) {

                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Welcome back 👋")
                            .font(.caption).foregroundColor(.secondary)
                        Text(currentUsername)
                            .font(.largeTitle).fontWeight(.bold)
                            .foregroundStyle(LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal)
                    .padding(.top)

                    // Create post button
                    Button { activeFlow = .scan } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill").font(.title2)
                            Text("Create a new post").font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(LinearGradient(colors: [.pink, .purple, .blue], startPoint: .leading, endPoint: .trailing))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .shadow(color: .purple.opacity(0.35), radius: 10, y: 5)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)

                    // Feed
                    if isLoading {
                        ProgressView("Loading posts…").padding(.top, 40)
                    } else if posts.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "tray").font(.system(size: 48)).foregroundColor(.gray)
                            Text("No posts yet").font(.subheadline).foregroundColor(.secondary)
                            Text("Be the first to drop something 👀").font(.caption).foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity).padding(.top, 40)
                    } else {
                        ForEach(posts) { post in
                            CatPostView(
                                post: post,
                                onLike: { toggleLike(post: post) },
                                onComment: { selectedPostForComments = post },
                                onDelete: post.ownerUID == Auth.auth().currentUser?.uid
                                    ? { Task { await deletePost(post) } } : nil
                            )
                            .padding(.horizontal)
                        }
                    }

                    Spacer(minLength: 30)
                }
            }
        }
        .onAppear  { startListening() }
        .onDisappear { listener?.remove() }
        .sheet(item: $selectedPostForComments) { CommentsView(post: $0) }
    }

    // MARK: - Listen
    private func startListening() {
        isLoading = true
        listener = Firestore.firestore()
            .collection("posts")
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { snapshot, error in
                isLoading = false
                if let error { print("❌", error.localizedDescription); return }
                posts = snapshot?.documents
                    .compactMap { Post(id: $0.documentID, data: $0.data()) } ?? []
            }
    }

    // MARK: - Like
    private func toggleLike(post: Post) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let ref = Firestore.firestore().collection("posts").document(post.id)
        if post.likes.contains(uid) {
            ref.updateData(["likes": FieldValue.arrayRemove([uid])])
        } else {
            ref.updateData(["likes": FieldValue.arrayUnion([uid])])
        }
    }

    // MARK: - Delete
    private func deletePost(_ post: Post) async {
        if let filename = post.imageURL.components(separatedBy: "/").last, !filename.isEmpty {
            try? await GitHubUploader.shared.deleteFile(path: "postImages/\(filename)")
        }
        try? await Firestore.firestore().collection("posts").document(post.id).delete()
    }
}
