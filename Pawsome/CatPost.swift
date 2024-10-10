import UIKit

struct CatPost: Codable {
    var username: String
    var image: Data // Use Data instead of UIImage for easier storage
    var timestamp: Date // Add a timestamp property to track post time

    // Computed property to convert Data back to UIImage
    var uiImage: UIImage? {
        return UIImage(data: image)
    }
}
