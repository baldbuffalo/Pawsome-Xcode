import Foundation

// ⚠️  SECURITY NOTE ────────────────────────────────────────────────────────────
// The GitHub token MUST NOT be hard-coded or committed to source control.
// Store it in a gitignored Secrets.xcconfig file:
//
//   GITHUB_TOKEN = ghp_YourNewTokenHere
//
// Reference it in Info.plist as:
//   <key>GitHubToken</key>
//   <string>$(GITHUB_TOKEN)</string>
//
// Add to .gitignore:  Secrets.xcconfig
// ─────────────────────────────────────────────────────────────────────────────

final class GitHubUploader {

    static let shared = GitHubUploader()
    private init() {}

    private let repo = "baldbuffalo/Pawsome-assets"

    private var token: String {
        guard
            let t = Bundle.main.object(forInfoDictionaryKey: "GitHubToken") as? String,
            !t.isEmpty
        else { fatalError("❌ GitHubToken missing from Info.plist — see SETUP.md") }
        return t
    }

    // MARK: - Upload raw Data
    /// Uploads `data` to `path` (relative to repo root) and returns the CDN download URL.
    func upload(_ data: Data, toPath path: String, message: String = "Upload") async throws -> String {
        let apiURL = URL(string: "https://api.github.com/repos/\(repo)/contents/\(path)")!

        var request = makeRequest(url: apiURL, method: "PUT")

        // Fetch SHA if file already exists (needed for updates)
        let existingSHA = try? await getFileSHA(path: path)

        var body: [String: Any] = [
            "message": message,
            "content": data.base64EncodedString()
        ]
        if let sha = existingSHA { body["sha"] = sha }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (responseData, response) = try await URLSession.shared.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

        guard (200...201).contains(statusCode) else {
            let msg = (try? JSONSerialization.jsonObject(with: responseData) as? [String: Any])?["message"] as? String
                ?? "HTTP \(statusCode)"
            throw GitHubError.uploadFailed(msg)
        }

        guard
            let json = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
            let content = json["content"] as? [String: Any],
            let downloadURL = content["download_url"] as? String
        else { throw GitHubError.invalidResponse }

        return downloadURL
    }

    // MARK: - Upload PlatformImage
    func uploadImage(
        _ image: PlatformImage,
        filename: String,
        folder: String = "postImages"
    ) async throws -> String {
        guard let data = image.jpegDataCompat(quality: 0.8) else {
            throw GitHubError.imageConversionFailed
        }
        return try await upload(data, toPath: "\(folder)/\(filename)", message: "Upload \(filename)")
    }

    // MARK: - Upload from file URL (used by ProfileView)
    func uploadImage(fileURL: URL, filename: String, folder: String = "profilePictures") async throws -> String {
        let data = try Data(contentsOf: fileURL)
        return try await upload(data, toPath: "\(folder)/\(filename)", message: "Upload profile picture")
    }

    // MARK: - Delete File
    func deleteFile(path: String) async throws {
        guard let sha = try await getFileSHA(path: path) else {
            print("⚠️ File not found at \(path) — skipping delete")
            return
        }

        var request = makeRequest(url: URL(string: "https://api.github.com/repos/\(repo)/contents/\(path)")!, method: "DELETE")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["message": "Delete \(path)", "sha": sha])

        let (_, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw GitHubError.deleteFailed
        }
    }

    // MARK: - Get SHA
    func getFileSHA(path: String) async throws -> String? {
        var request = makeRequest(
            url: URL(string: "https://api.github.com/repos/\(repo)/contents/\(path)")!,
            method: "GET"
        )
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
        return (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["sha"] as? String
    }

    // MARK: - Helper
    private func makeRequest(url: URL, method: String) -> URLRequest {
        var r = URLRequest(url: url)
        r.httpMethod = method
        r.setValue("token \(token)", forHTTPHeaderField: "Authorization")
        r.setValue("application/json", forHTTPHeaderField: "Content-Type")
        r.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        return r
    }

    // MARK: - Errors
    enum GitHubError: LocalizedError {
        case uploadFailed(String)
        case deleteFailed
        case invalidResponse
        case imageConversionFailed

        var errorDescription: String? {
            switch self {
            case .uploadFailed(let msg): return "GitHub upload failed: \(msg)"
            case .deleteFailed:          return "Failed to delete file from GitHub"
            case .invalidResponse:       return "Unexpected response from GitHub API"
            case .imageConversionFailed: return "Failed to convert image to JPEG data"
            }
        }
    }
}
