import FirebaseFirestore

struct CatPost: Identifiable, Codable {
    var id: String?
    var catName: String
    var catBreed: String?
    var location: String?
    var imageURL: String?
    var postDescription: String?
    var likes: Int
    var comments: [Comment] // ✅ Ensure this is always [Comment]
    var catAge: Int? // Add optional catAge

    init(id: String? = nil, catName: String, catBreed: String? = nil, location: String? = nil, imageURL: String? = nil, postDescription: String? = nil, likes: Int = 0, comments: [Comment] = [], catAge: Int? = nil) {
        self.id = id
        self.catName = catName
        self.catBreed = catBreed
        self.location = location
        self.imageURL = imageURL
        self.postDescription = postDescription
        self.likes = likes
        self.comments = comments
        self.catAge = catAge
    }

    // Convert Firestore document to CatPost
    static func fromDocument(_ document: DocumentSnapshot) -> CatPost? {
        guard let data = document.data() else { return nil }

        let commentsArray = data["comments"] as? [[String: Any]] ?? [] // ✅ Ensure it's an array of dictionaries
        let comments = commentsArray.compactMap { Comment(document: $0) }

        return CatPost(
            id: document.documentID,
            catName: data["catName"] as? String ?? "",
            catBreed: data["catBreed"] as? String,
            location: data["location"] as? String,
            imageURL: data["imageURL"] as? String,
            postDescription: data["postDescription"] as? String,
            likes: data["likes"] as? Int ?? 0,
            comments: comments,
            catAge: data["catAge"] as? Int // Add this line to handle the catAge field
        )
    }

    // Convert CatPost to Firestore format
    func toDictionary() -> [String: Any] {
        return [
            "catName": catName,
            "catBreed": catBreed ?? NSNull(),
            "location": location ?? NSNull(),
            "imageURL": imageURL ?? NSNull(),
            "postDescription": postDescription ?? NSNull(),
            "likes": likes,
            "comments": comments.map { $0.toDictionary() }, // ✅ Convert [Comment] to [[String: Any]]
            "catAge": catAge ?? NSNull() // Add catAge to dictionary, default to NSNull() if nil
        ]
    }
}
