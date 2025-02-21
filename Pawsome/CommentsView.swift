import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import Foundation

struct CommentsView: View {
    @EnvironmentObject var profileView: ProfileView
    @Binding var showComments: Bool
    var postID: String

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

    private func loadComments() async {
        do {
            let snapshot = try await db.collection("posts").document(postID).collection("comments")
                .order(by: "timestamp", descending: false)
                .getDocuments()

            comments = snapshot.documents.compactMap { document in
                var data = document.data()
                data["id"] = document.documentID
                return Comment(document: data)
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
        let commentData = Comment(
            id: UUID().uuidString, // Temporary ID
            text: commentText,
            username: profileView.username,
            profileImage: profileView.profileImage ?? "",
            timestamp: Date()
        ).toDictionary() // Use toDictionary to create Firestore-compatible data

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

struct CommentRow: View {
    let comment: Comment

    var body: some View {
        HStack {
            if let url = URL(string: comment.profileImage ?? ""), !(comment.profileImage ?? "").isEmpty {
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

struct Comment: Identifiable, Codable {
    var id: String
    var text: String
    var username: String
    var profileImage: String?
    var timestamp: Date

    enum CodingKeys: String, CodingKey {
        case id, text, username, profileImage, timestamp
    }

    init(id: String, text: String, username: String, profileImage: String?, timestamp: Date) {
        self.id = id
        self.text = text
        self.username = username
        self.profileImage = profileImage
        self.timestamp = timestamp
    }

    init?(document: [String: Any]) {
        guard let id = document["id"] as? String,
              let text = document["text"] as? String,
              let username = document["username"] as? String,
              let timestamp = document["timestamp"] as? Timestamp else {
            return nil
        }
        self.id = id
        self.text = text
        self.username = username
        self.profileImage = document["profileImage"] as? String
        self.timestamp = timestamp.dateValue()
    }

    // toDictionary method to convert the Comment object to a dictionary for Firestore storage
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "text": text,
            "username": username,
            "profileImage": profileImage ?? "",
            "timestamp": Timestamp(date: timestamp)
        ]
    }
}

private let commentDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
}()
