import Foundation

struct Comment: Identifiable {
    var id: String
    var text: String
    var userName: String

    // Initialize from a dictionary (optional, for local testing)
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

    // Convert to dictionary (optional, for local use)
    func toDictionary() -> [String: Any] {
        [
            "id": id,
            "text": text,
            "userName": userName
        ]
    }
}
