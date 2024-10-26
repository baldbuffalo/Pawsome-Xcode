import Foundation
import SwiftData

@Model
public class CatPost: Identifiable {
    public var id: UUID // Core Data will recognize this as a UUID type
    public var username: String
    public var name: String
    public var breed: String
    public var age: String
    public var location: String
    public var postDescription: String
    public var imageData: Data?
    public var likes: Int
    public var comments: [String]
    public var creationDate: Date
    public var modificationDate: Date

    // Initializer for the model
    public init(username: String, name: String, breed: String, age: String, location: String, postDescription: String, imageData: Data?) {
        self.id = UUID()
        self.username = username
        self.name = name
        self.breed = breed
        self.age = age
        self.location = location
        self.postDescription = postDescription
        self.imageData = imageData
        self.likes = 0
        self.comments = [] // Initialize as an empty array
        self.creationDate = Date()
        self.modificationDate = Date()
    }
}
