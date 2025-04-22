struct CatPost: Identifiable, Codable {
    var id: String?
    var catName: String
    var catBreed: String?
    var location: String?
    var imageData: Data
    var postDescription: String?
    var likes: Int
    var comments: [Comment]
    var catAge: Int?

    // Initializer for the CatPost struct
    init(id: String? = nil, catName: String, catBreed: String? = nil, location: String? = nil, imageData: Data, postDescription: String? = nil, likes: Int = 0, comments: [Comment] = [], catAge: Int? = nil) {
        self.id = id
        self.catName = catName
        self.catBreed = catBreed
        self.location = location
        self.imageData = imageData
        self.postDescription = postDescription
        self.likes = likes
        self.comments = comments
        self.catAge = catAge
    }

    // Convert Firestore document to CatPost
    static func fromDocument(_ document: DocumentSnapshot) -> CatPost? {
        guard let data = document.data() else { return nil }

        // Retrieve comments, assuming Comment is a struct with a valid initializer
        let commentsArray = data["comments"] as? [[String: Any]] ?? []
        let comments = commentsArray.compactMap { Comment(from: $0) }

        return CatPost(
            id: document.documentID,
            catName: data["catName"] as? String ?? "",
            catBreed: data["catBreed"] as? String,
            location: data["location"] as? String,
            imageData: data["imageData"] as! Data, // Assuming it's stored as Data
            postDescription: data["postDescription"] as? String,
            likes: data["likes"] as? Int ?? 0,
            comments: comments,
            catAge: data["catAge"] as? Int
        )
    }
}
