import Foundation

final class GitHubUploader {

    static let shared = GitHubUploader()
    private init() {}

    private let repo = "baldbuffalo/Pawsome-assets"
    private let folder = "profilePictures"

    private var token: String {
        guard let token = Bundle.main.object(
            forInfoDictionaryKey: "GitHubToken"
        ) as? String else {
            fatalError("❌ GitHubToken missing from Info.plist")
        }
        return token
    }

    // MARK: - Upload Image
    func uploadImage(fileURL: URL, filename: String) async throws -> String {
        let imageData = try Data(contentsOf: fileURL)
        let base64 = imageData.base64EncodedString()

        let url = URL(
            string: "https://api.github.com/repos/\(repo)/contents/\(folder)/\(filename)"
        )!

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("token \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "message": "Upload profile picture",
            "content": base64
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        guard
            let content = json?["content"] as? [String: Any],
            let downloadURL = content["download_url"] as? String
        else {
            throw NSError(domain: "GitHubUploader", code: 1)
        }

        return downloadURL
    }

    // MARK: - Get File SHA
    func getFileSHA(filename: String) async throws -> String? {
        let url = URL(
            string: "https://api.github.com/repos/\(repo)/contents/\(folder)/\(filename)"
        )!

        var request = URLRequest(url: url)
        request.setValue("token \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            return nil // file doesn't exist
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return json?["sha"] as? String
    }

    // MARK: - Delete Image
    func deleteImage(filename: String) async throws {
        guard let sha = try await getFileSHA(filename: filename) else {
            print("⚠️ No existing image to delete")
            return
        }

        let url = URL(
            string: "https://api.github.com/repos/\(repo)/contents/\(folder)/\(filename)"
        )!

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
}
