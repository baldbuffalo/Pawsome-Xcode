import Foundation
import FirebaseFirestore

struct CatPost: Identifiable, Codable {
    var id: String? // Firestore document ID
    var catName: String
    var catBreed: String?
    var location: String?
    var imageURL: String?
    var postDescription: String? // ✅ Added postDescription
    var likes: Int
    var comments: [String] // ✅ Ensure this is [String]

    init(id: String? = nil, catName: String, catBreed: String? = nil, location: String? = nil, imageURL: String? = nil, postDescription: String? = nil, likes: Int = 0, comments: [String] = []) { // ✅ Changed to [String]
        self.id = id
        self.catName = catName
        self.catBreed = catBreed
        self.location = location
        self.imageURL = imageURL
        self.postDescription = postDescription
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
            postDescription: data["postDescription"] as? String, // ✅ Added postDescription
            likes: data["likes"] as? Int ?? 0,
            comments: data["comments"] as? [String] ?? [] // ✅ Fetch comments properly
        )
    }

    // Convert CatPost to Firestore format
    func toDictionary() -> [String: Any] {
        return [
            "catName": catName,
            "catBreed": catBreed ?? NSNull(),
            "location": location ?? NSNull(),
            "imageURL": imageURL ?? NSNull(),
            "postDescription": postDescription ?? NSNull(), // ✅ Added postDescription
            "likes": likes,
            "comments": comments // ✅ Ensure comments are included in Firestore
        ]
    }
}
