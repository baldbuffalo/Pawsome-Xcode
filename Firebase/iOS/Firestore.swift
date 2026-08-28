import FirebaseFirestore

/// Apple-native Firestore adapter used by the iOS and macOS Pawsome targets.
///
/// The shared field/document contract lives at ../firestore.data.json.
/// This file maps that contract to FirebaseFirestore for Apple platforms.
public final class PawsomeFirestore {
    public static let shared = PawsomeFirestore()

    private let db = Firestore.firestore()

    private init() {}

    public func getUser(uid: String) async throws -> [String: Any]? {
        let snapshot = try await db.collection("users").document(uid).getDocument()
        return snapshot.exists ? snapshot.data() : nil
    }

    public func createOrUpdateUser(
        uid: String,
        username: String?,
        profilePic: String?
    ) async throws {
        let data: [String: Any] = [
            "username": username ?? "User",
            "profilePic": profilePic ?? "",
            "userNumber": 0,
            "createdAt": FieldValue.serverTimestamp()
        ]
        try await db.collection("users").document(uid).setData(data, merge: true)
    }

    public func updateUser(uid: String, fields: [String: Any]) async throws {
        try await db.collection("users").document(uid).setData(fields, merge: true)
    }

    public func getPosts(limit: Int = 50) async throws -> [[String: Any]] {
        let snapshot = try await db.collection("posts")
            .order(by: "timestamp", descending: true)
            .limit(to: limit)
            .getDocuments()

        return snapshot.documents.map { document in
            var data = document.data()
            data["id"] = document.documentID
            return data
        }
    }

    public func createPost(fields: [String: Any]) async throws -> String {
        let ref = try await db.collection("posts").addDocument(data: fields)
        return ref.documentID
    }

    public func deletePost(id: String) async throws {
        try await db.collection("posts").document(id).delete()
    }

    public func toggleLike(postId: String, uid: String, like: Bool) async throws {
        let value: Any = like
            ? FieldValue.arrayUnion([uid])
            : FieldValue.arrayRemove([uid])
        try await db.collection("posts").document(postId).updateData(["likes": value])
    }

    public func getComments(postId: String) async throws -> [[String: Any]] {
        let snapshot = try await db.collection("posts")
            .document(postId)
            .collection("comments")
            .order(by: "timestamp", descending: false)
            .getDocuments()

        return snapshot.documents.map { document in
            var data = document.data()
            data["id"] = document.documentID
            data["postId"] = postId
            return data
        }
    }

    public func addComment(postId: String, fields: [String: Any]) async throws -> String {
        let ref = try await db.collection("posts")
            .document(postId)
            .collection("comments")
            .addDocument(data: fields)

        try await db.collection("posts").document(postId).updateData([
            "commentCount": FieldValue.increment(Int64(1))
        ])

        return ref.documentID
    }

    public func deleteComment(postId: String, commentId: String) async throws {
        try await db.collection("posts")
            .document(postId)
            .collection("comments")
            .document(commentId)
            .delete()

        try await db.collection("posts").document(postId).updateData([
            "commentCount": FieldValue.increment(Int64(-1))
        ])
    }

    public func updateCommentText(
        postId: String,
        commentId: String,
        text: String
    ) async throws {
        try await db.collection("posts")
            .document(postId)
            .collection("comments")
            .document(commentId)
            .updateData(["text": text])
    }
}
