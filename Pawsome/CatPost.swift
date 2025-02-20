import Foundation
import FirebaseFirestore

struct CatPost: Identifiable, Codable {
    @DocumentID var id: String? // Firestore document ID
    var catName: String
    var catBreed: String?
    var location: String?
    var imageURL: String?
    var likes: Int
    var comments: [Comment]

    init(id: String? = nil, catName: String, catBreed: String? = nil, location: String? = nil, imageURL: String? = nil, likes: Int = 0, comments: [Comment] = []) {
        self.id = id
        self.catName = catName
        self.catBreed = catBreed
        self.location = location
        self.imageURL = imageURL
        self.likes = likes
        self.comments = comments
    }
}

struct Comment: Identifiable, Codable {
    var id: String
    var author: String
    var text: String
    var timestamp: Date

    init(id: String = UUID().uuidString, author: String, text: String, timestamp: Date = Date()) {
        self.id = id
        self.author = author
        self.text = text
        self.timestamp = timestamp
    }
}
