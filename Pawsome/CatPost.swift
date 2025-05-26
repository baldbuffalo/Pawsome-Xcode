import Foundation
import FirebaseFirestore

struct CatPost: Identifiable, Codable {
    var id: String?
    var catName: String
    var catBreed: String?
    var location: String?
    var imageURL: String?
    var postDescription: String?
    var likes: Int
    var comments: [String]
    var catAge: Int?
    var username: String?
    var timestamp: Date?
    var form: [String: String]? // ✅ Form data stored as [String: String]

    static func from(data: [String: Any], id: String) -> CatPost? {
        return CatPost(
            id: id,
            catName: data["catName"] as? String ?? "",
            catBreed: data["catBreed"] as? String,
            location: data["location"] as? String,
            imageURL: data["imageURL"] as? String,
            postDescription: data["description"] as? String,
            likes: data["likes"] as? Int ?? 0,
            comments: data["comments"] as? [String] ?? [],
            catAge: data["catAge"] as? Int,
            username: data["username"] as? String,
            timestamp: (data["timestamp"] as? Timestamp)?.dateValue(),
            form: data["form"] as? [String: String] // ✅ Decoding form field
        )
    }
}
