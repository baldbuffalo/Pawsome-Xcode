import FirebaseFirestore

struct Comment {
    var id: String
    var text: String
    var userName: String

    // Custom initializer for creating a Comment from a Firestore document
    init?(from dictionary: [String: Any]) {
        guard let id = dictionary["id"] as? String,
              let text = dictionary["text"] as? String,
              let userName = dictionary["userName"] as? String else {
            return nil
        }

        self.id = id
        self.text = text
        self.userName = userName
    }

    // Optional: Convert the Comment object back into a dictionary for Firestore
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "text": text,
            "userName": userName
        ]
    }
}
