import Foundation

struct CatPost: Identifiable, Codable, Hashable {
    var id: String
    var catName: String
    var catBreed: String?
    var catAge: Int
    var location: String?
    var postDescription: String?
    var likes: Int
    var username: String
    var comments: [Comment]  // Updated to use the Comment struct
}
