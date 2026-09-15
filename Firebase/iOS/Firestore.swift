import FirebaseFirestore

/// Apple-native Firestore adapter used by the iOS and macOS Pawsome targets.
/// Firestore schema follows the Android implementation exactly.
public final class PawsomeFirestore {
    public static let shared = PawsomeFirestore()
    private let db = Firestore.firestore()
    private init() {}

    public func getUser(uid: String) async throws -> [String: Any]? {
        let snapshot = try await db.collection("users").document(uid).getDocument()
        return snapshot.exists ? snapshot.data() : nil
    }

    public func createOrUpdateUser(uid: String, username: String?, profilePic: String?, loginMethod: String = "Unknown") async throws {
        let userRef = db.collection("users").document(uid)
        let counterRef = db.collection("counter").document("users")
        try await db.runTransaction { transaction, errorPointer in
            do {
                let existing = try transaction.getDocument(userRef)
                if existing.exists { return nil }
                let counterSnapshot = try transaction.getDocument(counterRef)
                let lastUserID = counterSnapshot.data()?["lastUserID"] as? Int ?? 0
                let nextUserID = lastUserID + 1
                transaction.setData(["lastUserID": nextUserID], forDocument: counterRef, merge: true)
                transaction.setData(["Username": username ?? "User", "ProfilePic": profilePic ?? "", "UserID": nextUserID, "LoginMethod": loginMethod, "JoinedOn": FieldValue.serverTimestamp()], forDocument: userRef, merge: false)
            } catch { errorPointer?.pointee = error as NSError }
            return nil
        }
    }

    public func updateUser(uid: String, fields: [String: Any]) async throws { try await db.collection("users").document(uid).setData(fields, merge: true) }

    public func getPosts(limit: Int = 50) async throws -> [[String: Any]] {
        let snapshot = try await db.collection("posts").order(by: "PostedAt", descending: true).limit(to: limit).getDocuments()
        return snapshot.documents.map { document in var data = document.data(); data["id"] = document.documentID; return data }
    }

    public func createPost(fields: [String: Any]) async throws -> String {
        var fields = fields
        guard fields["UserID"] != nil else { throw NSError(domain: "PawsomeFirestore", code: 1, userInfo: [NSLocalizedDescriptionKey: "UserID is required when creating a post"]) }
        if fields["PostedAt"] == nil { fields["PostedAt"] = FieldValue.serverTimestamp() }
        return try await db.collection("posts").addDocument(data: fields).documentID
    }

    public func deletePost(id: String) async throws { try await db.collection("posts").document(id).delete() }

    public func toggleLike(postId: String, uid: String, like: Bool) async throws {
        let value: Any = like ? FieldValue.arrayUnion([uid]) : FieldValue.arrayRemove([uid])
        try await db.collection("posts").document(postId).updateData(["likes": value])
    }
}
