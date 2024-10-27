import Foundation
import CoreData

@objc(CatPost)
public class CatPost: NSManagedObject {
    // No need for context here anymore

    // Create a new CatPost
    static func create(title: String, imageUrl: String, in context: NSManagedObjectContext) -> CatPost {
        let catPost = CatPost(context: context)
        catPost.title = title
        catPost.imageUrl = imageUrl
        saveContext(in: context)
        return catPost
    }

    // Fetch all CatPosts
    static func fetchAll(in context: NSManagedObjectContext) -> [CatPost] {
        let fetchRequest: NSFetchRequest<CatPost> = CatPost.fetchRequest()
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Failed to fetch CatPosts: \(error)")
            return []
        }
    }

    // Delete a CatPost
    static func delete(_ catPost: CatPost, in context: NSManagedObjectContext) {
        context.delete(catPost)
        saveContext(in: context)
    }

    // Save context changes
    private static func saveContext(in context: NSManagedObjectContext) {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Failed to save context: \(error)")
            }
        }
    }
}
