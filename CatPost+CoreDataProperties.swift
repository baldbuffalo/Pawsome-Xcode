import Foundation
import CoreData

@objc(CatPost) // Necessary for Core Data to recognize the class
public class CatPost: NSManagedObject, Identifiable {
    
    // Core Data attributes
    @NSManaged public var age: String?
    @NSManaged public var breed: String?
    @NSManaged public var comments: [String]? // Optional array of strings
    @NSManaged public var creationDate: Date?
    @NSManaged public var id: UUID? // UUID should be generated upon creation
    @NSManaged public var imageData: Data?
    @NSManaged public var likes: Int16
    @NSManaged public var location: String?
    @NSManaged public var modificationDate: Date?
    @NSManaged public var name: String?
    @NSManaged public var postDescription: String?
    @NSManaged public var username: String?
    
    // Initializer for the model
    public class func createCatPost(username: String, name: String, breed: String, age: String, location: String, postDescription: String, imageData: Data?, context: NSManagedObjectContext) -> CatPost {
        let catPost = CatPost(context: context)
        catPost.id = UUID() // Automatically generate a new UUID for each post
        catPost.username = username
        catPost.name = name
        catPost.breed = breed
        catPost.age = age
        catPost.location = location
        catPost.postDescription = postDescription
        catPost.imageData = imageData
        catPost.likes = 0 // Initialize likes to 0
        catPost.comments = [] // Initialize comments to an empty array
        catPost.creationDate = Date() // Set creation date to now
        catPost.modificationDate = Date() // Set modification date to now
        return catPost
    }
}

// Core Data fetch request extension
extension CatPost {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CatPost> {
        return NSFetchRequest<CatPost>(entityName: "CatPost")
    }
}
