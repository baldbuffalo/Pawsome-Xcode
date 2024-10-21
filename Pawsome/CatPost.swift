import Foundation
import SwiftData

@Model
public class CatPost {
    // Define the properties of the model
    var id: UUID
    var username: String
    var name: String
    var breed: String
    var age: String
    var location: String
    var postDescription: String
    var imageData: Data?
    var likes: Int
    var comments: [String]
    var creationDate: Date
    var modificationDate: Date

    // Initializer for the model
    init(username: String, name: String, breed: String, age: String, location: String, postDescription: String, imageData: Data?) {
        self.id = UUID()
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
