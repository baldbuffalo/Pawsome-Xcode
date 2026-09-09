import SwiftUI
import FirebaseAuth

struct AdminView: View {
    @ObservedObject var appState: PawsomeApp.AppState
    @State private var posts: [[String: Any]] = []
    @State private var users: [[String: Any]] = []
    @State private var stats: (posts: Int, users: Int) = (0, 0)
    @State private var maintenanceMode = false
    @State private var adsEnabled = true
    @State private var announcementTitle = ""
    @State private var announcementBody = ""
    @State private var busy = false
    @State private var message = ""

    var body: some View {
        NavigationStack {
            List {
                Section("Overview") {
                    LabeledContent("Posts", value: "\(stats.posts)")
                    LabeledContent("Users", value: "\(stats.users)")
                    LabeledContent("Firebase", value: "pawsome-90cb3")
                }
                Section("Posts") {
                    if posts.isEmpty { Text("No posts found").foregroundStyle(.secondary) }
                    ForEach(posts.indices, id: \.self) { index in
                        let post = posts[index]
                        HStack {
                            VStack(alignment: .leading) {
                                Text(post["CatName"] as? String ?? post["catName"] as? String ?? "Untitled").font(.headline)
                                Text(post["status"] as? String ?? "UNKNOWN").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button(role: .destructive) { Task { await deletePost(post) } } label: { Image(systemName: "trash") }
                        }
                    }
                }
                Section("App settings") {
                    Toggle("Maintenance mode", isOn: $maintenanceMode)
                    Toggle("Ads enabled", isOn: $adsEnabled)
                    TextField("Announcement title", text: $announcementTitle)
                    TextField("Announcement message", text: $announcementBody, axis: .vertical)
                    Button("Save app settings") { Task { await saveSettings() } }
                }
                if !users.isEmpty {
                    Section("Users") {
                        ForEach(users.indices, id: \.self) { index in
                            let user = users[index]
                            Text(user["username"] as? String ?? user["Username"] as? String ?? "User")
                        }
                    }
                }
                if !message.isEmpty { Section { Text(message).foregroundStyle(.secondary) } }
            }
            .navigationTitle("Admin")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Refresh") { Task { await refresh() } }.disabled(busy) } }
            .overlay { if busy { ProgressView().padding().background(.thinMaterial).clipShape(RoundedRectangle(cornerRadius: 12)) } }
            .task { await refresh() }
        }
    }

    private let baseURL = URL(string: "https://europe-west1-pawsome-90cb3.cloudfunctions.net")!

    private func call(_ name: String, data: [String: Any] = [:]) async throws -> [String: Any] {
        guard let user = Auth.auth().currentUser else { throw NSError(domain: "PawsomeAdmin", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not signed in"]) }
        let token = try await user.getIDTokenResult().token
        var request = URLRequest(url: baseURL.appendingPathComponent(name))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["data": data])
        let (body, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let text = String(data: body, encoding: .utf8) ?? "Firebase function failed"
            throw NSError(domain: "PawsomeAdmin", code: 1, userInfo: [NSLocalizedDescriptionKey: text])
        }
        return (try JSONSerialization.jsonObject(with: body) as? [String: Any])?["data"] as? [String: Any] ?? [:]
    }

    private func refresh() async {
        busy = true; message = ""
        do {
            async let s = call("adminGetStats")
            async let p = call("adminListDocuments", data: ["collectionPath": "posts", "limit": 100])
            async let u = call("adminListDocuments", data: ["collectionPath": "users", "limit": 100])
            async let c = call("adminGetAppConfig")
            let (statsData, postsData, usersData, configData) = try await (s, p, u, c)
            stats = (statsData["posts"] as? Int ?? 0, statsData["users"] as? Int ?? 0)
            posts = postsData["documents"] as? [[String: Any]] ?? []
            users = usersData["documents"] as? [[String: Any]] ?? []
            let config = configData["fields"] as? [String: Any] ?? [:]
            maintenanceMode = config["maintenanceMode"] as? Bool ?? false
            adsEnabled = config["adsEnabled"] as? Bool ?? true
            announcementTitle = config["announcementTitle"] as? String ?? ""
            announcementBody = config["announcementBody"] as? String ?? ""
        } catch { message = error.localizedDescription }
        busy = false
    }

    private func deletePost(_ post: [String: Any]) async {
        guard let path = post["path"] as? String else { return }
        busy = true
        defer { busy = false }
        do { _ = try await call("adminDeleteDocument", data: ["path": path]); await refresh() }
        catch { message = error.localizedDescription }
    }

    private func saveSettings() async {
        busy = true
        defer { busy = false }
        do {
            _ = try await call("adminSetAppConfig", data: ["fields": [
                "maintenanceMode": maintenanceMode,
                "adsEnabled": adsEnabled,
                "announcementTitle": announcementTitle,
                "announcementBody": announcementBody
            ]])
            message = "Saved to Firebase."
        } catch { message = error.localizedDescription }
    }
}
