import SwiftUI

struct CatPost: Identifiable, Codable {
    var id: UUID // Unique ID for the post
    var name: String // Cat's name
    var breed: String // Cat's breed
    var age: String // Cat's age
    var location: String // Location of the cat
    var likes: Int // Number of likes the post has received
    var comments: [String] // Array of comments on the post
    var image: UIImage? // Optional image of the cat
    var username: String // Username of the person who posted
    var creationTime: Date // Time when the post was created
}
