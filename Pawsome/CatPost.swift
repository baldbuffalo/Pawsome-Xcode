import Foundation
import SwiftData

/// A model representing a post about a cat.
@Model
public class CatPostModel: Identifiable {
    /// The unique identifier for the cat post.
    public var id: UUID
    /// The username of the person who posted.
    public var username: String
    /// The name of the cat.
    public var name: String
    /// The breed of the cat.
    public var breed: String
    /// The age of the cat.
    public var age: String
    /// The location of the cat.
    public var location: String
    /// A description of the post.
    public var postDescription: String
    /// The image data of the cat.
    public var imageData: Data?
    /// The number of likes on the post.
    public var likes: Int
    /// Comments on the post.
    public var comments: [String]
    /// The date the post was created.
    public var creationDate: Date
    /// The date the post was last modified.
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
        self.likes = 0 // Initialize likes to 0
        self.comments = [] // Initialize comments as an empty array
        self.creationDate = Date() // Set creation date to now
        self.modificationDate = Date() // Set modification date to now
    }

    /// Adds a comment to the post.
    public func addComment(_ comment: String) {
        comments.append(comment)
    }

    /// Increments the like count for the post.
    public func likePost() {
        likes += 1
    }
}
