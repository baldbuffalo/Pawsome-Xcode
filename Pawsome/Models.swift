import Foundation

struct Comment: Identifiable, Codable, Hashable {
    let id: String
    let text: String
    let username: String
    let profileImage: String
    let timestamp: Date
}

struct CatPost: Identifiable, Codable, Hashable {
    var id: String
    var catName: String
    var catBreed: String?
    var catAge: Int
    var location: String?
    var postDescription: String?
    var likes: Int
    var username: String
    var comments: [Comment]  // Using the shared Comment struct
}

enum MediaPicker {
    enum MediaType: String, CaseIterable {
        case library
        case photo
        case video

        var displayName: String {
            switch self {
            case .library:
                return "Photo Library"
            case .photo:
                return "Camera (Photo)"
            case .video:
                return "Camera (Video)"
            }
        }
    }
}

