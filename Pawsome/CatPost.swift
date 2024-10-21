import Foundation
import CoreData
import SwiftData

@objc(CatPost) // Matches the entity name in your .xcdatamodeld file
public class CatPost: NSManagedObject, PersistentModel {
    
    // Required properties
    @NSManaged public var id: UUID
    @NSManaged public var username: String
    @NSManaged public var name: String
    @NSManaged public var breed: String
    @NSManaged public var age: String
    @NSManaged public var location: String
    @NSManaged public var postDescription: String // Renamed to avoid using "description"
    @NSManaged public var imageData: Data?
    @NSManaged public var likes: Int64
    @NSManaged public var comments: [String]? // This should be a transformable type or a separate entity

    // Required initializer for PersistentModel
    required convenience init(context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forEntityName: "CatPost", in: context)!
        self.init(entity: entity, insertInto: context)
    }

    // Additional method required for PersistentModel (if applicable)
    public static func fetchRequest() -> NSFetchRequest<CatPost> {
        return NSFetchRequest<CatPost>(entityName: "CatPost")
    }
    
    // Initializer for convenience
    convenience init(context: NSManagedObjectContext, username: String, name: String, breed: String, age: String, location: String, postDescription: String, imageData: Data?) {
        self.init(context: context) // Call the required initializer
        
        self.id = UUID()
        self.username = username
        self.name = name
        self.breed = breed
        self.age = age
        self.location = location
        self.postDescription = postDescription // Updated to match the property
        self.imageData = imageData
        self.likes = 0
        self.comments = [] // Initialize comments as an empty array
    }
}
