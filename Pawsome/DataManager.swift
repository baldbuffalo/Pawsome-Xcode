import CoreData
import SwiftUI

class DataManager: ObservableObject {
    @Published var catPosts: [CatPost] = []
    
    private let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    init() {
        fetchPosts()
    }

    func fetchPosts() {
        let request: NSFetchRequest<CatPost> = CatPost.fetchRequest()
        do {
            catPosts = try context.fetch(request)
        } catch {
            print("Failed to fetch posts: \(error.localizedDescription)")
        }
    }

    func savePost(catName: String, breed: String, age: String, location: String, description: String, image: UIImage?) {
        let newPost = CatPost(context: context)
        newPost.catName = catName
        newPost.catBreed = breed
        newPost.catAge = Int32(age) ?? 0
        newPost.location = location
        newPost.content = description
        newPost.timestamp = Date()

        if let image = image {
            newPost.imageData = image.pngData()
        }

        do {
            try context.save()
            fetchPosts() // Refresh the list of posts after saving
        } catch {
            print("Error saving post: \(error.localizedDescription)")
        }
    }
}
