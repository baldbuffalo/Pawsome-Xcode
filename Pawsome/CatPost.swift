import FirebaseFirestore

struct CatPost: Identifiable, Codable {
    var id: String?
    var catName: String
    var catBreed: String?
    var location: String?
    var imageData: Data
    var postDescription: String?
    var likes: Int
    var comments: [String] // Assuming comments are represented as an array of strings
    var catAge: Int?

    // Initializer for the CatPost struct
    init(id: String? = nil, catName: String, catBreed: String? = nil, location: String? = nil, imageData: Data, postDescription: String? = nil, likes: Int = 0, comments: [String] = [], catAge: Int? = nil) {
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
        guard let data = document.data() else { return nil }  // Safely unwrap the document data

        // Retrieve comments (assuming they are stored as an array of strings)
        let comments = data["comments"] as? [String] ?? []

        // Safely decode imageData (if it exists)
        guard let imageData = data["imageData"] as? Data else {
            print("Error: imageData is missing or not in the correct format.")
            return nil
        }

        return CatPost(
            id: document.documentID,
            catName: data["catName"] as? String ?? "",
            catBreed: data["catBreed"] as? String,
            location: data["location"] as? String,
            imageData: imageData,
            postDescription: data["postDescription"] as? String,
            likes: data["likes"] as? Int ?? 0,
            comments: comments,
            catAge: data["catAge"] as? Int
        )
    }
}
