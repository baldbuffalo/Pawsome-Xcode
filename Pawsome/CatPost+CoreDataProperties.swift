import Foundation
import CoreData

extension CatPost {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CatPost> {
        return NSFetchRequest<CatPost>(entityName: "CatPost")
    }

    @NSManaged public var title: String?
    @NSManaged public var imageUrl: String?
    @NSManaged public var username: String?
    @NSManaged public var imageData: Data?
    @NSManaged public var name: String?
    @NSManaged public var breed: String?
    @NSManaged public var age: String?
    @NSManaged public var location: String?
    @NSManaged public var postDescription: String?
    @NSManaged public var timestamp: Date?
    @NSManaged public var likes: Int16 // Assuming likes is an integer property
}
