import Foundation
import FirebaseFirestore

// MARK: - Post
struct Post: Identifiable {
    let id: String
    let catName: String
    let description: String
    let age: String
    let imageURL: String
    let userID: Int
    let username: String
    let profilePic: String
    let timestamp: Timestamp
    var likes: [String]
    var commentCount: Int

    // Compatibility aliases for existing UI code. Firestore uses UserID/Username/ProfilePic.
    var ownerUID: String { String(userID) }
    var ownerUsername: String { username }
    var ownerProfilePic: String { profilePic }

    init?(id: String, data: [String: Any]) {
        guard
            let catName = data["catName"] as? String,
            let imageURL = data["imageURL"] as? String,
            let userID = data["UserID"] as? Int
        else { return nil }

        self.id = id
        self.catName = catName
        self.description = data["description"] as? String ?? ""
        self.age = data["age"] as? String ?? ""
        self.imageURL = imageURL
        self.userID = userID
        self.username = data["Username"] as? String ?? "User"
        self.profilePic = data["ProfilePic"] as? String ?? ""
        self.timestamp = data["PostedAt"] as? Timestamp ?? Timestamp()
        self.likes = data["likes"] as? [String] ?? []
        self.commentCount = data["commentCount"] as? Int ?? 0
    }
}

// MARK: - PostComment
struct PostComment: Identifiable {
    let id: String
    let postId: String
    let text: String
    let userID: Int
    let username: String
    let profilePic: String
    let timestamp: Timestamp

    // Compatibility aliases for existing UI code.
    var ownerUID: String { String(userID) }
    var ownerUsername: String { username }
    var ownerProfilePic: String { profilePic }

    init?(id: String, postId: String, data: [String: Any]) {
        guard
            let text = data["text"] as? String,
            let userID = data["UserID"] as? Int
        else { return nil }

        self.id = id
        self.postId = postId
        self.text = text
        self.userID = userID
        self.username = data["Username"] as? String ?? "User"
        self.profilePic = data["ProfilePic"] as? String ?? ""
        self.timestamp = data["timestamp"] as? Timestamp ?? Timestamp()
    }
}
