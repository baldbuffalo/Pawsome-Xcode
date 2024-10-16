import Foundation

struct CatPost: Identifiable, Codable {
    var id = UUID() // Unique identifier for each post
    var name: String
    var breed: String
    var age: String
    var imageData: Data? // Image data stored as Data
    var username: String // Username of the person who posted
    var location: String // New property for location
    var description: String // New property for description
    var creationTime: Date // Timestamp of when the post was created
    var likes: Int // Number of likes for the post
    var comments: [String] // Comments should be an array

    // Initializer for easy creation
    init(name: String, breed: String, age: String, imageData: Data?, username: String, location: String, description: String) {
        self.name = name
        self.breed = breed
        self.age = age
        self.imageData = imageData
        self.username = username
        self.location = location // Initialize location
        self.description = description // Initialize description
        self.creationTime = Date() // Set to current time
        self.likes = 0 // Initialize likes to zero
        self.comments = [] // Initialize with an empty array
    }
}
