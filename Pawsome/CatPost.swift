import Foundation
import FirebaseFirestore

struct CatPost: Identifiable, Codable {
    var id: String? // Firestore document ID
    var catName: String
    var catBreed: String?
    var location: String?
    var imageURL: String?
    var likes: Int
    var comments: [Comment] // Now using Comment from CommentsView.swift

    init(id: String? = nil, catName: String, catBreed: String? = nil, location: String? = nil, imageURL: String? = nil, likes: Int = 0, comments: [Comment] = []) {
        self.id = id
        self.catName = catName
        self.catBreed = catBreed
        self.location = location
        self.imageURL = imageURL
        self.likes = likes
        self.comments = comments
    }

    // Convert Firestore document to CatPost
    static func fromDocument(_ document: DocumentSnapshot) -> CatPost? {
        guard let data = document.data() else { return nil }
        return CatPost(
            id: document.documentID,
            catName: data["catName"] as? String ?? "",
            catBreed: data["catBreed"] as? String,
            location: data["location"] as? String,
            imageURL: data["imageURL"] as? String,
            likes: data["likes"] as? Int ?? 0,
            comments: [] // Handle comments separately
        )
    }

    // Convert CatPost to Firestore format
    func toDictionary() -> [String: Any] {
        return [
            "catName": catName,
            "catBreed": catBreed ?? NSNull(),
            "location": location ?? NSNull(),
            "imageURL": imageURL ?? NSNull(),
            "likes": likes
        ]
    }
}
