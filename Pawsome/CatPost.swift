import Foundation

struct CatPost: Identifiable, Codable {
    var id: UUID
    var username: String
    var name: String
    var breed: String
    var age: String
    var location: String
    var description: String
    var imageData: Data?
    var likes: Int
    var commentsCount: Int // To track the number of comments

    // Initializer for convenience
    init(username: String, name: String, breed: String, age: String, location: String, description: String, imageData: Data?) {
        self.id = UUID()
        self.username = username
        self.name = name
        self.breed = breed
        self.age = age
        self.location = location
        self.description = description
        self.imageData = imageData
        self.likes = 0
        self.commentsCount = 0 // Initialize comments count
    }
}
