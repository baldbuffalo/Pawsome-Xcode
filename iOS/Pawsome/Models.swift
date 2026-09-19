import Foundation
import FirebaseFirestore

enum PostStatus: String, CaseIterable, Identifiable {
    case LOST
    case FOUND
    case REUNITED

    var id: String { rawValue }
    var emoji: String {
        switch self { case .LOST: return "🔴"; case .FOUND: return "🟢"; case .REUNITED: return "🟡" }
    }
    var displayName: String {
        switch self { case .LOST: return "Lost"; case .FOUND: return "Found"; case .REUNITED: return "Reunited" }
    }
}

struct Post: Identifiable {
    let id: String
    let catName: String
    let description: String
    let age: String
    let breed: String
    let location: String
    let status: PostStatus
    let imageURL: String
    let userID: Int
    let username: String
    let profilePic: String
    let timestamp: Timestamp
    var likes: [String]

    var ownerUID: String { String(userID) }
    var ownerUsername: String { username }
    var ownerProfilePic: String { profilePic }

    init?(id: String, data: [String: Any]) {
        guard let catName = data["CatName"] as? String ?? data["catName"] as? String,
              let imageURL = data["imageURL"] as? String,
              let userID = data["UserID"] as? Int else { return nil }
        self.id = id
        self.catName = catName
        self.description = data["description"] as? String ?? ""
        self.age = data["CatAge"] as? String ?? data["age"] as? String ?? ""
        self.breed = data["Breed"] as? String ?? data["breed"] as? String ?? ""
        self.location = data["location"] as? String ?? ""
        self.status = PostStatus(rawValue: data["status"] as? String ?? "LOST") ?? .LOST
        self.imageURL = imageURL
        self.userID = userID
        self.username = data["Username"] as? String ?? "User"
        self.profilePic = data["ProfilePic"] as? String ?? ""
        self.timestamp = data["PostedAt"] as? Timestamp ?? Timestamp()
        self.likes = data["likes"] as? [String] ?? []
    }
}
