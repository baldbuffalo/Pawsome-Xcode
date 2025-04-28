import FirebaseFirestore

struct CatPost: Identifiable, Codable {
    var id: String?
    var catName: String
    var catBreed: String?
    var location: String?
    var imageData: Data
    var postDescription: String?
    var likes: Int
    var comments: [String]
    var catAge: Int?
    var form: [String: Any]? // ✅ Added here

    // Initializer
    init(id: String? = nil, catName: String, catBreed: String? = nil, location: String? = nil, imageData: Data, postDescription: String? = nil, likes: Int = 0, comments: [String] = [], catAge: Int? = nil, form: [String: Any]? = nil) {
        self.id = id
        self.catName = catName
        self.catBreed = catBreed
        self.location = location
        self.imageData = imageData
        self.postDescription = postDescription
        self.likes = likes
        self.comments = comments
        self.catAge = catAge
        self.form = form // ✅ Added here
    }

    // Firestore document to CatPost
    static func fromDocument(_ document: DocumentSnapshot) -> CatPost? {
        guard let data = document.data() else { return nil }

        let comments = data["comments"] as? [String] ?? []

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
            catAge: data["catAge"] as? Int,
            form: data["form"] as? [String: Any] // ✅ Also load 'form' from Firestore
        )
    }
}
