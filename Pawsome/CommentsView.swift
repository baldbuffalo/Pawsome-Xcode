import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

struct CommentsView: View {
    @EnvironmentObject var profileView: ProfileView
    @Binding var showComments: Bool
    var postID: String

    @State private var commentText: String = ""
    @State private var comments: [[String: Any]] = [] // Store Firebase data
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
                    List(comments, id: \.self) { comment in
                        if let commentID = comment["commentID"] as? String {
                            CommentRow(comment: comment)
                        }
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

    private func loadComments() async {
        do {
            let snapshot = try await db.collection("posts").document(postID).collection("comments")
                .order(by: "timestamp", descending: false)
                .getDocuments()

            // Map each document to include a commentID
            comments = snapshot.documents.map { document in
                var commentData = document.data()
                commentData["commentID"] = document.documentID // Add the documentID as commentID
                return commentData
            }
        } catch {
            errorMessage = "Failed to fetch comments: \(error.localizedDescription)"
        }
        isLoading = false
    }

    private func saveComment() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        guard !commentText.isEmpty else { return }

        let timestamp = Timestamp(date: Date())
        let commentData: [String: Any] = [
            "text": commentText,
            "username": profileView.username,
            "timestamp": timestamp,
            "profileImage": profileView.profileImage ?? "",
            "commentID": UUID().uuidString // Add a temporary comment ID
        ]

        db.collection("posts").document(postID).collection("comments").addDocument(data: commentData) { error in
            if let error = error {
                print("Failed to save comment: \(error.localizedDescription)")
            } else {
                comments.append(commentData)
                commentText = ""
            }
        }
    }
}

struct CommentRow: View {
    let comment: [String: Any]

    var body: some View {
        HStack {
            if let profileImageURL = comment["profileImage"] as? String, let url = URL(string: profileImageURL), !profileImageURL.isEmpty {
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
                if let username = comment["username"] as? String {
                    Text(username)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                if let text = comment["text"] as? String {
                    Text(text)
                        .font(.body)
                }
                if let timestamp = comment["timestamp"] as? Timestamp {
                    Text(timestamp.dateValue(), formatter: commentDateFormatter)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
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
