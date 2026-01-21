import Foundation
#if os(iOS)
import UIKit
typealias PlatformImage = UIImage
#elseif os(macOS)
import AppKit
typealias PlatformImage = NSImage
#endif

final class GitHubUploader {

    static let shared = GitHubUploader()

    private init() {}

    // MARK: - Config
    private let repo = "baldbuffalo/Pawsome-assets"
    private let folder = "profilePictures"

    private var token: String {
        guard let token = Bundle.main.object(forInfoDictionaryKey: "GitHubToken") as? String else {
            fatalError("❌ GitHubToken missing from Info.plist")
        }
        return token
    }

    // MARK: - Upload Image
    func uploadProfileImage(fileURL: URL, userID: String) async throws -> String {

        let filename = "\(userID).jpg"
        guard let imageData = PlatformImageJPEGConverter.jpegData(from: PlatformImage(contentsOfFile: fileURL.path)!)
        else { throw NSError(domain: "GitHubUploader", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid image"]) }

        let base64 = imageData.base64EncodedString()

        let url = URL(string: "https://api.github.com/repos/\(repo)/contents/\(folder)/\(filename)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("token \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "message": "Upload profile picture for \(userID)",
            "content": base64
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (responseData, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: responseData) as? [String: Any]
        let content = json?["content"] as? [String: Any]
        guard let downloadURL = content?["download_url"] as? String else {
            throw NSError(domain: "GitHubUploader", code: 2, userInfo: [NSLocalizedDescriptionKey: "No download URL returned"])
        }

        return downloadURL
    }

    // MARK: - Delete Image
    func deleteImage(filename: String, sha: String) async throws {

        let url = URL(string: "https://api.github.com/repos/\(repo)/contents/\(folder)/\(filename)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("token \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "message": "Delete old profile picture",
            "sha": sha
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        _ = try await URLSession.shared.data(for: request)
    }

    // MARK: - Extract filename from GitHub URL
    func filenameFromURL(_ url: String) -> String? {
        URL(string: url)?.lastPathComponent
    }
}

// MARK: - PlatformImage → JPEG Data
enum PlatformImageJPEGConverter {
    static func jpegData(from image: PlatformImage) -> Data? {
        #if os(iOS)
        return image.jpegData(compressionQuality: 0.85)
        #elseif os(macOS)
        guard
            let tiff = image.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiff)
        else { return nil }

        return bitmap.representation(
            using: .jpeg,
            properties: [.compressionFactor: 0.85] as [NSBitmapImageRep.PropertyKey: Any]
        )
        #endif
    }
}
