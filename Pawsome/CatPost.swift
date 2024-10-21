import Foundation
import CoreData
import SwiftData

@objc(CatPost)
public class CatPost: NSManagedObject, PersistentModel {
    @NSManaged public var id: UUID
    @NSManaged public var username: String
    @NSManaged public var name: String
    @NSManaged public var breed: String
    @NSManaged public var age: String
    @NSManaged public var location: String
    @NSManaged public var postDescription: String
    @NSManaged public var imageData: Data?
    @NSManaged public var likes: Int64
    @NSManaged public var comments: [String]?

    // If the PersistentModel protocol requires a date property
    @NSManaged public var creationDate: Date?
    @NSManaged public var modificationDate: Date?

    required convenience init(context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forEntityName: "CatPost", in: context)!
        self.init(entity: entity, insertInto: context)
    }

    convenience init(context: NSManagedObjectContext, username: String, name: String, breed: String, age: String, location: String, postDescription: String, imageData: Data?) {
        self.init(context: context)
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
        self.creationDate = Date() // Set the creation date
        self.modificationDate = Date() // Set the modification date
    }

    public static func fetchRequest() -> NSFetchRequest<CatPost> {
        return NSFetchRequest<CatPost>(entityName: "CatPost")
    }

    // Example of a required property/method
    public var modelID: UUID {
        return id
    }

    // If the protocol requires methods for saving or deleting
    public func save() {
        // Implement save functionality
    }

    public func delete() {
        // Implement delete functionality
    }
}

// Extension for additional functionality
extension CatPost {
    public static func defaultFetchRequest() -> NSFetchRequest<CatPost> {
        let request = fetchRequest()
        request.predicate = nil
        return request
    }
}
