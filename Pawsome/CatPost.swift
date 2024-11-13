import Foundation
import FirebaseFirestore

struct CatPost: Identifiable, Codable {
    @DocumentID var id: String? // Use Firebase document ID as unique identifier
    let username: String
    let catName: String
    let catBreed: String
    let location: String
    var likes: Int
    var postDescription: String
    var timestamp: Date
    var profileImageURL: String // URL for profile image in Firebase Storage
    var postImageURL: String // URL for post image in Firebase Storage
}
