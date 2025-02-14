import Foundation

struct CatPost: Identifiable, Codable {
    var id: String
    var catName: String
    var catBreed: String?
    var catAge: Int
    var location: String?
    var imageURL: String?
    var likes: Int
    var comments: [String]
}
