import SwiftUI

struct CatPost: Codable, Identifiable {
    var id: UUID
    var name: String
    var breed: String
    var age: String
    var imageData: Data? // Use Data to hold image binary data
    var username: String
    var creationTime: Date // This should also be Decodable
    var likes: Int
    var comments: [String]

    // Computed property to get UIImage from imageData
    var image: UIImage? {
        if let data = imageData {
            return UIImage(data: data)
        }
        return nil
    }
}
