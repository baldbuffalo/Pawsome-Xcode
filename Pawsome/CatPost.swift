import FirebaseFirestore

struct CatPost: Identifiable {
    var id: String?
    var catName: String
    var catBreed: String?
    var location: String?
    var imageData: Data? // Store image as Data
    var postDescription: String?
    var likes: Int
    var comments: [Comment] // Ensure Comment struct is properly handled
    var catAge: Int?

    // Initialize CatPost from Firestore document
    init(id: String? = nil, catName: String, catBreed: String? = nil, location: String? = nil, imageData: Data? = nil, postDescription: String? = nil, likes: Int = 0, comments: [Comment] = [], catAge: Int? = nil) {
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

        // Manually retrieve data from Firestore and initialize the CatPost object
        let catName = data["catName"] as? String ?? ""
        let catBreed = data["catBreed"] as? String
        let location = data["location"] as? String
        let imageData = data["imageData"] as? Data
        let postDescription = data["postDescription"] as? String
        let likes = data["likes"] as? Int ?? 0
        let commentsData = data["comments"] as? [[String: Any]] ?? []
        let comments = commentsData.compactMap { Comment(from: $0) }
        let catAge = data["catAge"] as? Int
        
        return CatPost(id: document.documentID,
                       catName: catName,
                       catBreed: catBreed,
                       location: location,
                       imageData: imageData,
                       postDescription: postDescription,
                       likes: likes,
                       comments: comments,
                       catAge: catAge)
    }

    // Convert CatPost to Firestore dictionary (used when saving)
    func toDictionary() -> [String: Any] {
        return [
            "catName": catName,
            "catBreed": catBreed ?? "",
            "location": location ?? "",
            "imageData": imageData ?? Data(),
            "postDescription": postDescription ?? "",
            "likes": likes,
            "comments": comments.map { $0.toDictionary() }, // Assuming Comment has toDictionary()
            "catAge": catAge as Any
        ]
    }
}
