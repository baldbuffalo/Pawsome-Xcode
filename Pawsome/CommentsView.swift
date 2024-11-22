import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct CommentsView: View {
    @EnvironmentObject var profileView: ProfileView
    @Binding var showComments: Bool
    var postID: String
    var saveCommentToFirebase: (String, String) -> Void

    @State private var commentText: String = ""
    @State private var comments: [Comment] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    private let db = Firestore.firestore()

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading Comments...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
            } else {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                } else {
                    List(comments) { comment in
                        CommentRow(comment: comment)
                    }
                }
            }

            commentInputSection
        }
        .onAppear {
            Task {
                await loadComments()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Close") {
                    showComments = false
                }
            }
        }
    }

    private var commentInputSection: some View {
        HStack {
            #if available(iOS 15, *)
            TextField("Add a comment...", text: $commentText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .disableAutocorrection(true)
                .textInputAutocapitalization(.sentences)
            #else
            TextField("Add a comment...", text: $commentText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .disableAutocorrection(true)
                .autocapitalization(.sentences)
            #endif

            Button(action: saveComment) {
                Text("Send")
                    .bold()
                    .foregroundColor(commentText.isEmpty ? .gray : .blue)
            }
            .padding()
            .disabled(commentText.isEmpty)
        }
        .padding(.bottom)
    }

    private func loadComments() async {
        do {
            let snapshot = try await db.collection("posts").document(postID).collection("comments")
                .order(by: "timestamp", descending: false)
                .getDocuments()
            
            comments = snapshot.documents.compactMap { document in
                try? document.data(as: Comment.self)
            }
        } catch {
            errorMessage = "Failed to fetch comments: \(error.localizedDescription)"
        }
        isLoading = false
    }

    private func saveComment() {
        guard !commentText.isEmpty else { return }

        saveCommentToFirebase(postID, commentText)

        let newComment = Comment(
            text: commentText,
            username: profileView.username,
            timestamp: Date(),
            profilePictureUrl: profileView.profilePictureUrl
        )

        comments.append(newComment)
        commentText = ""
    }
}

struct CommentRow: View {
    let comment: Comment

    var body: some View {
        HStack {
            if let profilePictureUrl = comment.profilePictureUrl, let url = URL(string: profilePictureUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        .padding(.trailing, 8)
                } placeholder: {
                    Image("defaultProfileImage")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        .padding(.trailing, 8)
                }
            } else {
                Image("defaultProfileImage")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .padding(.trailing, 8)
            }

            VStack(alignment: .leading) {
                Text(comment.username)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text(comment.text)
                    .font(.body)
                Text(comment.timestamp, formatter: commentDateFormatter)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

private let commentDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
}()

struct Comment: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var text: String
    var username: String
    var timestamp: Date
    var profilePictureUrl: String?
}
