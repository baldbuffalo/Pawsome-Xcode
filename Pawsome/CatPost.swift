import Foundation

struct CatPost: Identifiable, Codable, Hashable {
    var id: UUID
    var username: String
    var name: String
    var breed: String
    var age: String
    var location: String
    var description: String
    var imageData: Data?
    var likes: Int
    var comments: [String] // Array to store comments

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
        self.comments = [] // Initialize comments as an empty array
    }

    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(username)
        hasher.combine(name)
        hasher.combine(breed)
        hasher.combine(age)
        hasher.combine(location)
        hasher.combine(description)
        hasher.combine(likes)
        hasher.combine(comments) // Include comments for full hashability
    }

    static func ==(lhs: CatPost, rhs: CatPost) -> Bool {
        return lhs.id == rhs.id // Compare based on unique ID
    }
}
