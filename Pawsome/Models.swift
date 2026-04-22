import Foundation
import FirebaseFirestore

// MARK: - Post
struct Post: Identifiable {
    let id: String
    let catName: String
    let description: String
    let age: String
    let imageURL: String
    let ownerUID: String
    let ownerUsername: String
    let ownerProfilePic: String
    let timestamp: Timestamp
    var likes: [String]
    var commentCount: Int

    init?(id: String, data: [String: Any]) {
        guard
            let catName  = data["catName"]  as? String,
            let imageURL = data["imageURL"] as? String,
            let ownerUID = data["ownerUID"] as? String
        else { return nil }

        self.id              = id
        self.catName         = catName
        self.description     = data["description"]      as? String ?? ""
        self.age             = data["age"]              as? String ?? ""
        self.imageURL        = imageURL
        self.ownerUID        = ownerUID
        self.ownerUsername   = data["ownerUsername"]    as? String ?? "User"
        self.ownerProfilePic = data["ownerProfilePic"]  as? String ?? ""
        self.timestamp       = data["timestamp"]        as? Timestamp ?? Timestamp()
        self.likes           = data["likes"]            as? [String] ?? []
        self.commentCount    = data["commentCount"]     as? Int ?? 0
    }
}

// MARK: - PostComment
struct PostComment: Identifiable {
    let id: String
    let postId: String
    let text: String
    let ownerUID: String
    let ownerUsername: String
    let ownerProfilePic: String
    let timestamp: Timestamp

    init?(id: String, postId: String, data: [String: Any]) {
        guard
            let text     = data["text"]     as? String,
            let ownerUID = data["ownerUID"] as? String
        else { return nil }

        self.id              = id
        self.postId          = postId
        self.text            = text
        self.ownerUID        = ownerUID
        self.ownerUsername   = data["ownerUsername"]   as? String ?? "User"
        self.ownerProfilePic = data["ownerProfilePic"] as? String ?? ""
        self.timestamp       = data["timestamp"]       as? Timestamp ?? Timestamp()
    }
}
