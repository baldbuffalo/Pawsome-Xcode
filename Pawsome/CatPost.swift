import Foundation
import FirebaseFirestore
import Combine

struct CatPost: Identifiable, Codable {
    var id: String?
    var catName: String
    var catBreed: String?
    var location: String?
    var imageURL: String?
    var postDescription: String?
    var likes: Int
    var comments: [String]
    var catAge: Int?
    var username: String?
    var timestamp: Date?
    var form: [String: String]? // ✅ Form data

    static func from(data: [String: Any], id: String) -> CatPost {
        return CatPost(
            id: id,
            catName: data["catName"] as? String ?? "Unknown Cat",
            catBreed: data["catBreed"] as? String,
            location: data["location"] as? String,
            imageURL: data["imageURL"] as? String,
            postDescription: data["description"] as? String,
            likes: data["likes"] as? Int ?? 0,
            comments: data["comments"] as? [String] ?? [],
            catAge: data["catAge"] as? Int,
            username: data["username"] as? String,
            timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date(),
            form: data["form"] as? [String: String]
        )
    }
}

// MARK: - ViewModel

class CatPostViewModel: ObservableObject {
    @Published var posts: [CatPost] = []
    private var db = Firestore.firestore()

    func fetchPosts() {
        db.collection("catPosts")
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching posts: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents else { return }
                self.posts = documents.map { doc in
                    CatPost.from(data: doc.data(), id: doc.documentID)
                }
            }
    }

    func addPost(_ post: CatPost) {
        var data = try? Firestore.Encoder().encode(post)
        db.collection("catPosts").addDocument(data: data ?? [:]) { error in
            if let error = error {
                print("Error adding post: \(error.localizedDescription)")
            } else {
                print("✅ Post added successfully")
            }
        }
    }
}
