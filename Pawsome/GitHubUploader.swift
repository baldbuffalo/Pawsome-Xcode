import Foundation

struct GitHubUploader {

    private var token: String {
        guard let token = Bundle.main.object(
            forInfoDictionaryKey: "GitHubToken"
        ) as? String else {
            fatalError("❌ GitHubToken missing from Info.plist")
        }
        return token
    }

    private let repo = "baldbuffalo/Pawsome-assets"
    private let folder = "profilePictures"

    func uploadImage(
        filename: String,
        imageData: Data
    ) async throws -> String {

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
        let content = json?["content"] as? [String: Any]

        return content?["download_url"] as? String ?? ""
    }
}
