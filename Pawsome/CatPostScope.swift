import Foundation
import CoreData

// MARK: - CatPost Scope

extension CatPost {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CatPost> {
        return NSFetchRequest<CatPost>(entityName: "CatPost")
    }

    // Example method to fetch all CatPosts
    public static func fetchAllPosts(context: NSManagedObjectContext) -> [CatPost]? {
        let fetchRequest: NSFetchRequest<CatPost> = CatPost.fetchRequest()
        
        do {
            let posts = try context.fetch(fetchRequest)
            return posts
        } catch {
            print("Failed to fetch CatPosts: \(error)")
            return nil
        }
    }

    // Example method to delete a CatPost
    public static func deletePost(post: CatPost, context: NSManagedObjectContext) {
        context.delete(post)
        do {
            try context.save()
        } catch {
            print("Failed to delete CatPost: \(error)")
        }
    }
    
    // Example method to update a CatPost
    public static func updatePost(post: CatPost, with newData: CatPostData, context: NSManagedObjectContext) {
        post.username = newData.username
        post.name = newData.name
        post.breed = newData.breed
        post.age = newData.age
        post.location = newData.location
        post.postDescription = newData.postDescription
        post.imageData = newData.imageData
        post.modificationDate = Date()
        
        do {
            try context.save()
        } catch {
            print("Failed to update CatPost: \(error)")
        }
    }
}

// Struct to encapsulate CatPost data for updates
public struct CatPostData {
    var username: String
    var name: String
    var breed: String
    var age: String
    var location: String
    var postDescription: String
    var imageData: Data?
}
