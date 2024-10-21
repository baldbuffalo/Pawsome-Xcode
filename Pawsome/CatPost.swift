import Foundation
import SwiftData

@Model
public class CatPost: Identifiable {
    @Attribute(.uuid) public var id: UUID
    @Attribute(.string) public var username: String
    @Attribute(.string) public var name: String
    @Attribute(.string) public var breed: String
    @Attribute(.string) public var age: String
    @Attribute(.string) public var location: String
    @Attribute(.string) public var postDescription: String
    @Attribute(.data) public var imageData: Data?
    @Attribute(.int) public var likes: Int
    @Attribute(.array) public var comments: [String]
    @Attribute(.date) public var creationDate: Date
    @Attribute(.date) public var modificationDate: Date

    // Initializer for the model
    public init(username: String, name: String, breed: String, age: String, location: String, postDescription: String, imageData: Data?) {
        self.id = UUID() // Automatically generated UUID
        self.username = username
        self.name = name
        self.breed = breed
        self.age = age
        self.location = location
        self.postDescription = postDescription
        self.imageData = imageData
        self.likes = 0
        self.comments = []
        self.creationDate = Date()
        self.modificationDate = Date()
    }
}
