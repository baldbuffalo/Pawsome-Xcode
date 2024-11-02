import CoreData
import Combine

class DataManager: ObservableObject {
    @Published var posts: [CatPost] = []
    private var context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
        fetchPosts()
    }
    
    func fetchPosts() {
        let request: NSFetchRequest<CatPost> = CatPost.fetchRequest()
        do {
            posts = try context.fetch(request)
        } catch {
            print("Failed to fetch posts: \(error)")
        }
    }

    func addPost(username: String, catName: String, catBreed: String, catAge: Int32, location: String, content: String, imageData: Data?) {
        let newPost = CatPost(context: context)
        newPost.username = username
        newPost.catName = catName
        newPost.catBreed = catBreed
        newPost.catAge = catAge
        newPost.location = location
        newPost.content = content
        newPost.timestamp = Date()
        newPost.imageData = imageData

        savePost()
    }

    private func savePost() {
        do {
            try context.save()
            fetchPosts() // Refresh the posts after saving
        } catch {
            print("Failed to save post: \(error)")
        }
    }
}
