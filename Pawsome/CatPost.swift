import Foundation
import SwiftUI

struct CatPost: Identifiable, Codable {
    var id: UUID = UUID() // Correctly initialize the UUID
    var name: String
    var breed: String
    var age: String
    var imageData: Data? // Optional property to store image data
    var username: String
    var creationTime: Date = Date() // Initialize to the current date
    var likes: Int = 0 // Default to 0 likes
    var comments: [String] = [] // Default to an empty array for comments

    // Computed property to get UIImage from imageData
    var image: UIImage? {
        if let data = imageData {
            return UIImage(data: data)
        }
        return nil
    }
}
