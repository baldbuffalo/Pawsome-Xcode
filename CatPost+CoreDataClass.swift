import Foundation
import CoreData

@objc(CatPost)
public class CatPost: NSManagedObject {

    // MARK: - Core Data Properties
    @NSManaged public var title: String?
    @NSManaged public var imageUrl: String?

    // MARK: - Core Data Management

    // Get the managed object context from the AppDelegate or Core Data stack
    private static var context: NSManagedObjectContext {
        return (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    }

    // Create a new CatPost
    static func create(title: String, imageUrl: String) -> CatPost {
        let catPost = CatPost(context: context)
        catPost.title = title
        catPost.imageUrl = imageUrl
        saveContext()
        return catPost
    }

    // Fetch all CatPosts
    static func fetchAll() -> [CatPost] {
        let fetchRequest: NSFetchRequest<CatPost> = CatPost.fetchRequest()
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Failed to fetch CatPosts: \(error)")
            return []
        }
    }

    // Delete a CatPost
    static func delete(_ catPost: CatPost) {
        context.delete(catPost)
        saveContext()
    }

    // Save context changes
    private static func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Failed to save context: \(error)")
            }
        }
    }
}
