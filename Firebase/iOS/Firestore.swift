import FirebaseFirestore

/// Apple-native Firestore adapter used by the iOS and macOS Pawsome targets.
public final class PawsomeFirestore {
    public static let shared = PawsomeFirestore()
    private let db = Firestore.firestore()
    private init() {}

    public func getUser(uid: String) async throws -> [String: Any]? {
        let snapshot = try await db.collection("users").document(uid).getDocument()
        return snapshot.exists ? snapshot.data() : nil
    }

    public func createOrUpdateUser(uid: String, username: String?, profilePic: String?) async throws {
        let userRef = db.collection("users").document(uid)
        let counterRef = db.collection("counter").document("users")
        try await db.runTransaction { transaction, errorPointer in
            do {
                let counterSnapshot = try transaction.getDocument(counterRef)
                let lastUserNumber = counterSnapshot.data()?["lastUserNumber"] as? Int ?? 0
                let nextUserNumber = lastUserNumber + 1
                transaction.setData(["lastUserNumber": nextUserNumber], forDocument: counterRef, merge: true)
                transaction.setData([
                    "username": username ?? "User",
                    "profilePic": profilePic ?? "",
                    "userNumber": nextUserNumber,
                    "joinedOn": FieldValue.serverTimestamp()
                ], forDocument: userRef, merge: false)
            } catch { errorPointer?.pointee = error }
            return nil
        }
    }

    public func updateUser(uid: String, fields: [String: Any]) async throws {
        try await db.collection("users").document(uid).setData(fields, merge: true)
    }

    public func getPosts(limit: Int = 50) async throws -> [[String: Any]] {
        let snapshot = try await db.collection("posts").order(by: "PostedAt", descending: true).limit(to: limit).getDocuments()
        return snapshot.documents.map { document in var data = document.data(); data["id"] = document.documentID; return data }
    }

    public func createPost(fields: [String: Any]) async throws -> String {
        var fields = fields
        if fields["UserId"] == nil {
            throw NSError(domain: "PawsomeFirestore", code: 1, userInfo: [NSLocalizedDescriptionKey: "UserId is required when creating a post"])
        }
        if fields["PostedAt"] == nil {
            fields["PostedAt"] = FieldValue.serverTimestamp()
        }
        let ref = try await db.collection("posts").addDocument(data: fields)
        return ref.documentID
    }

    public func deletePost(id: String) async throws { try await db.collection("posts").document(id).delete() }

    public func toggleLike(postId: String, uid: String, like: Bool) async throws {
        let value: Any = like ? FieldValue.arrayUnion([uid]) : FieldValue.arrayRemove([uid])
        try await db.collection("posts").document(postId).updateData(["likes": value])
    }

    public func getComments(postId: String) async throws -> [[String: Any]] {
        let snapshot = try await db.collection("posts").document(postId).collection("comments").order(by: "timestamp", descending: false).getDocuments()
        return snapshot.documents.map { document in var data = document.data(); data["id"] = document.documentID; data["postId"] = postId; return data }
    }

    public func addComment(postId: String, fields: [String: Any]) async throws -> String {
        let ref = try await db.collection("posts").document(postId).collection("comments").addDocument(data: fields)
        try await db.collection("posts").document(postId).updateData(["commentCount": FieldValue.increment(Int64(1))])
        return ref.documentID
    }

    public func deleteComment(postId: String, commentId: String) async throws {
        try await db.collection("posts").document(postId).collection("comments").document(commentId).delete()
        try await db.collection("posts").document(postId).updateData(["commentCount": FieldValue.increment(Int64(-1))])
    }

    public func updateCommentText(postId: String, commentId: String, text: String) async throws {
        try await db.collection("posts").document(postId).collection("comments").document(commentId).updateData(["text": text])
    }
}
