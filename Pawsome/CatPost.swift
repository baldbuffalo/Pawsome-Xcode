

import SwiftUI

struct CatPost: Identifiable {
    let id = UUID()
    var name: String
    var breed: String
    var age: String
    var location: String
    var image: UIImage?
    var comments: [String] = []
    var likes: Int = 0
}
