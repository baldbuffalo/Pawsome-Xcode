import Foundation
import SwiftUI

struct CatPost: Identifiable, Codable {
    var id: UUID
    var name: String
    var breed: String
    var age: String
    var imageData: Data?
    var username: String
    var creationTime: Date
    var likes: Int
    var comments: [String] // Optional array for comments


    // Computed property to get UIImage from imageData
    var image: UIImage? {
        if let data = imageData {
            return UIImage(data: data)
        }
        return nil
    }
}
