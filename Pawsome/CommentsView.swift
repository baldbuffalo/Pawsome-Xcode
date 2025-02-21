import SwiftUI
import FirebaseFirestore

// MARK: - Comment Model (Nested within CommentsView.swift)
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

// MARK: - CommentsView
struct CommentsView: View {
    @State private var comments: [Comment] = []
    @State private var newCommentText: String = ""

    let postId: String

    var body: some View {
        VStack {
            // List of comments
            List(comments) { comment in
                VStack(alignment: .leading) {
                    Text(comment.username)
                        .font(.headline)
                    Text(comment.text)
                        .font(.body)
                    if let profileImage = comment.profileImage {
                        Image(systemName: "person.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                    }
                }
            }
            
            // New comment input
            HStack {
                TextField("Write a comment", text: $newCommentText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: postComment) {
                    Text("Post")
                }
                .disabled(newCommentText.isEmpty)
            }
            .padding()
        }
        .onAppear {
            loadComments()
        }
    }

    // Function to load comments from Firestore
    func loadComments() {
        let db = Firestore.firestore()
        db.collection("catPosts")
            .document(postId)
            .collection("comments")
            .order(by: "timestamp")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error loading comments: \(error)")
                    return
                }
                comments = snapshot?.documents.compactMap { document in
                    Comment(document: document.data())
                } ?? []
            }
    }

    // Function to post a new comment
    func postComment() {
        let db = Firestore.firestore()
        let newComment = Comment(
            id: UUID().uuidString,
            text: newCommentText,
            username: "User", // Replace with actual user info
            profileImage: nil, // Optionally add profile image URL
            timestamp: Date()
        )

        let commentData = newComment.toDictionary()

        db.collection("catPosts")
            .document(postId)
            .collection("comments")
            .document(newComment.id)
            .setData(commentData) { error in
                if let error = error {
                    print("Error posting comment: \(error)")
                } else {
                    comments.append(newComment)
                    newCommentText = ""
                }
            }
    }
}
