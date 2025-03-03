import SwiftUI
import FirebaseFirestore

// ✅ Comment Model now conforms to Codable
struct Comment: Identifiable, Codable {
    var id: String
    var user: String
    var text: String
    var timestamp: Date

    // ✅ Init from Firestore document
    init?(document: [String: Any]) {
        guard let user = document["user"] as? String,
              let text = document["text"] as? String,
              let timestamp = (document["timestamp"] as? Timestamp)?.dateValue() else {
            return nil
        }

        self.id = document["id"] as? String ?? UUID().uuidString
        self.user = user
        self.text = text
        self.timestamp = timestamp
    }

    // ✅ Convert Comment to Firestore format
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "user": user,
            "text": text,
            "timestamp": Timestamp(date: timestamp) // ✅ Firestore-compatible timestamp
        ]
    }
}
