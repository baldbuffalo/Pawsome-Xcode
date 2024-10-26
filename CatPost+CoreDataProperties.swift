
import Foundation
import CoreData

// MARK: - CatPost Core Data Properties
extension CatPost {

    // Fetch request for the CatPost entity
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CatPost> {
        return NSFetchRequest<CatPost>(entityName: "CatPost")
    }

    // Core Data properties for the CatPost entity
    @NSManaged public var age: String?                  // The age of the cat
    @NSManaged public var breed: String?                // The breed of the cat
    @NSManaged public var comments: NSObject?           // Comments related to the post (consider changing type if needed)
    @NSManaged public var creationDate: Date?           // The creation date of the post
    @NSManaged public var imageData: Data?              // The image data for the post
    @NSManaged public var likes: Int16                   // The number of likes for the post
    @NSManaged public var location: String?              // The location associated with the post
    @NSManaged public var modificationDate: Date?        // The last modification date of the post
    @NSManaged public var name: String?                  // The name of the cat
    @NSManaged public var postDescription: String?       // Description of the post
    @NSManaged public var username: String?              // Username of the person who created the post
}

// MARK: - Identifiable Conformance
extension CatPost: Identifiable {
}
