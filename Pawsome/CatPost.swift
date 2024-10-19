import Foundation
import CoreData

@objc(CatPost) // Matches the entity name in your .xcdatamodeld file
public class CatPost: NSManagedObject, Hashable {
    @NSManaged public var id: UUID
    @NSManaged public var username: String
    @NSManaged public var name: String
    @NSManaged public var breed: String
    @NSManaged public var age: String
    @NSManaged public var location: String
    @NSManaged public var postDescription: String // Avoid using "description" since it's a reserved keyword
    @NSManaged public var imageData: Data?
    @NSManaged public var likes: Int64
    @NSManaged public var comments: [String]? // This should be a transformable type or a separate entity

    // Initializer for convenience
    convenience init(context: NSManagedObjectContext, username: String, name: String, breed: String, age: String, location: String, description: String, imageData: Data?) {
        let entity = NSEntityDescription.entity(forEntityName: "CatPost", in: context)!
        self.init(entity: entity, insertInto: context)
        
        self.id = UUID()
        self.username = username
        self.name = name
        self.breed = breed
        self.age = age
        self.location = location
        self.postDescription = description
        self.imageData = imageData
        self.likes = 0
        self.comments = [] // Initialize comments as an empty array
    }

    // Hashable conformance
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(username)
        hasher.combine(name)
        hasher.combine(breed)
        hasher.combine(age)
        hasher.combine(location)
        hasher.combine(postDescription)
        hasher.combine(likes)
        hasher.combine(comments)
    }

    public static func ==(lhs: CatPost, rhs: CatPost) -> Bool {
        return lhs.id == rhs.id // Compare based on unique ID
    }
}
