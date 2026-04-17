import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct CommentsView: View {

    let post: Post
    @EnvironmentObject var appState: PawsomeApp.AppState
    @Environment(\.dismiss) private var dismiss

    @State private var comments:    [PostComment] = []
    @State private var newComment   = ""
    @State private var isLoading    = true
    @State private var isPosting    = false
    @State private var listener:    ListenerRegistration?

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {

                // ── Post summary ────────────────────────────────────────
                HStack(spacing: 10) {
                    AsyncImage(url: URL(string: post.imageURL)) { phase in
                        if let img = phase.image { img.resizable().scaledToFill() }
                        else { Color.gray.opacity(0.2) }
                    }
                    .frame(width: 52, height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 3) {
                        Text(post.catName).font(.headline)
                        Text("by \(post.ownerUsername)")
                            .font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding()
                .background(.ultraThinMaterial)

                Divider()

                // ── Comments list ───────────────────────────────────────
                if isLoading {
                    Spacer()
                    ProgressView("Loading comments…")
                    Spacer()
                } else if comments.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "bubble.right")
                            .font(.system(size: 42)).foregroundColor(.secondary)
                        Text("No comments yet")
                            .font(.subheadline).foregroundColor(.secondary)
                        Text("Be the first to comment! 🐾")
                            .font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 14) {
                            ForEach(comments) { comment in
                                CommentRow(
                                    comment: comment,
                                    currentUID: Auth.auth().currentUser?.uid ?? ""
                                ) {
                                    deleteComment(comment)
                                }
                            }
                        }
                        .padding()
                    }
                }

                Divider()

                // ── Input bar ───────────────────────────────────────────
                HStack(spacing: 10) {
                    TextField("Add a comment…", text: $newComment, axis: .vertical)
                        .lineLimit(1...5)
                        .textFieldStyle(.roundedBorder)

                    Button {
                        Task { await postComment() }
                    } label: {
                        if isPosting {
                            ProgressView().tint(.purple)
                        } else {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.title2)
                                .foregroundColor(canPost ? .purple : .gray)
                        }
                    }
                    .disabled(!canPost || isPosting)
                }
                .padding()
            }
            .navigationTitle("Comments")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onAppear  { attachListener() }
        .onDisappear { listener?.remove() }
    }

    // MARK: - Helpers
    private var canPost: Bool {
        !newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Firestore listener
    private func attachListener() {
        isLoading = true
        listener?.remove()

        listener = Firestore.firestore()
            .collection("posts")
            .document(post.id)
            .collection("comments")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snapshot, error in
                isLoading = false
                if let error {
                    print("❌ Comments listener error:", error.localizedDescription)
                    return
                }
                comments = snapshot?.documents
                    .compactMap { PostComment(id: $0.documentID, data: $0.data()) } ?? []
            }
    }

    // MARK: - Post comment
    private func postComment() async {
        let text = newComment.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let uid = Auth.auth().currentUser?.uid else { return }

        isPosting = true
        let data: [String: Any] = [
            "text":            text,
            "ownerUID":        uid,
            "ownerUsername":   appState.currentUsername,
            "ownerProfilePic": appState.profileImageURL ?? "",
            "timestamp":       Timestamp()
        ]

        do {
            try await Firestore.firestore()
                .collection("posts")
                .document(post.id)
                .collection("comments")
                .addDocument(data: data)
            await MainActor.run {
                newComment = ""
                isPosting  = false
            }
        } catch {
            await MainActor.run { isPosting = false }
            print("❌ Post comment error:", error.localizedDescription)
        }
    }

    // MARK: - Delete comment
    private func deleteComment(_ comment: PostComment) {
        guard comment.ownerUID == Auth.auth().currentUser?.uid else { return }
        Task {
            try? await Firestore.firestore()
                .collection("posts").document(post.id)
                .collection("comments").document(comment.id)
                .delete()
        }
    }
}

// MARK: - Comment Row
struct CommentRow: View {
    let comment: PostComment
    let currentUID: String
    var onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            AsyncImage(url: URL(string: comment.ownerProfilePic)) { phase in
                if let img = phase.image { img.resizable().scaledToFill() }
                else { Image(systemName: "person.circle.fill").resizable().foregroundColor(.gray) }
            }
            .frame(width: 32, height: 32)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline) {
                    Text(comment.ownerUsername).font(.caption.weight(.semibold))
                    Text(comment.timestamp.timeAgoDisplay())
                        .font(.caption2).foregroundColor(.secondary)
                    Spacer()
                    if comment.ownerUID == currentUID {
                        Button(role: .destructive) { onDelete() } label: {
                            Image(systemName: "xmark")
                                .font(.caption2)
                                .foregroundColor(.red.opacity(0.55))
                        }
                        .buttonStyle(.plain)
                    }
                }
                Text(comment.text).font(.subheadline)
            }
        }
    }
}
