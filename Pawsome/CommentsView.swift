import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

// MARK: - Comment Struct
struct Comment: Hashable {
    let id: String
    let text: String
    let username: String
    let profileImage: String
    let timestamp: Date
}

// MARK: - CommentsView
struct CommentsView: View {
    @EnvironmentObject var profileView: ProfileView
    @Binding var showComments: Bool
    var postID: String

    @State private var commentText: String = ""
    @State private var comments: [Comment] = [] // Use Comment struct
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
                    List(comments, id: \.id) { comment in
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
            TextField("Add a comment...", text: $commentText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .disableAutocorrection(true)

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

    // MARK: - Load Comments
    private func loadComments() async {
        do {
            let snapshot = try await db.collection("posts")
                .document(postID)
                .collection("comments")
                .order(by: "timestamp", descending: false)
                .getDocuments()

            comments = snapshot.documents.compactMap { document in
                let data = document.data()
                guard
                    let text = data["text"] as? String,
                    let username = data["username"] as? String,
                    let profileImage = data["profileImage"] as? String,
                    let timestamp = data["timestamp"] as? Timestamp
                else {
                    return nil
                }
                return Comment(
                    id: document.documentID,
                    text: text,
                    username: username,
                    profileImage: profileImage,
                    timestamp: timestamp.dateValue()
                )
            }
            errorMessage = nil // Clear any previous errors
        } catch {
            errorMessage = "Failed to fetch comments: \(error.localizedDescription)"
        }
        isLoading = false
    }

    // MARK: - Save Comment
    private func saveComment() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        guard !commentText.isEmpty else { return }

        let timestamp = Timestamp(date: Date())
        let commentData: [String: Any] = [
            "text": commentText,
            "username": profileView.username,
            "profileImage": profileView.profileImage ?? "",
            "timestamp": timestamp
        ]

        db.collection("posts").document(postID).collection("comments").addDocument(data: commentData) { error in
            if let error = error {
                print("Failed to save comment: \(error.localizedDescription)")
            } else {
                let newComment = Comment(
                    id: UUID().uuidString, // Temporary ID
                    text: commentText,
                    username: profileView.username,
                    profileImage: profileView.profileImage ?? "",
                    timestamp: Date()
                )
                comments.append(newComment)
                commentText = ""
            }
        }
    }
}

// MARK: - CommentRow
struct CommentRow: View {
    let comment: Comment

    var body: some View {
        HStack {
            if let url = URL(string: comment.profileImage), !comment.profileImage.isEmpty {
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

// MARK: - Date Formatter
private let commentDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
}()
