import SwiftUI
import FirebaseAuth
import GoogleSignIn

@main
struct PawsomeApp: App {
    // MARK: - App state
    @State private var isLoggedIn = false
    @State private var currentUsername: String = ""
    @State private var profileImageURL: String = ""

    var body: some Scene {
        WindowGroup {
            contentView
                .onAppear { setupAuthStateObserver() }
        }
    }

    // MARK: - Main content
    @ViewBuilder
    private var contentView: some View {
        if isLoggedIn {
            mainTabView
        } else {
            LoginView(
                isLoggedIn: $isLoggedIn,
                username: $currentUsername,
                profileImage: Binding<String?>(
                    get: { profileImageURL.isEmpty ? nil : profileImageURL },
                    set: { profileImageURL = $0 ?? "" }
                )
            )
        }
    }

    private var mainTabView: some View {
        TabView {
            HomeView(
                isLoggedIn: $isLoggedIn,
                currentUsername: $currentUsername,
                profileImageURL: Binding<String?>(
                    get: { profileImageURL.isEmpty ? nil : profileImageURL },
                    set: { profileImageURL = $0 ?? "" }
                ),
                onPostCreated: { print("🔥 Post created!") }
            )
            .tabItem { Label("Home", systemImage: "house.fill") }

            ScanView(
                username: currentUsername,
                onPostCreated: { _ in print("📸 Scan post created!") }
            )
            .tabItem { Label("Scan", systemImage: "camera.viewfinder") }

            ProfileView(
                isLoggedIn: $isLoggedIn,
                currentUsername: $currentUsername,
                profileImageURL: Binding<String?>(
                    get: { profileImageURL.isEmpty ? nil : profileImageURL },
                    set: { profileImageURL = $0 ?? "" }
                )
            )
            .tabItem { Label("Profile", systemImage: "person.fill") }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Firebase Auth listener
    private func setupAuthStateObserver() {
        _ = Auth.auth().addStateDidChangeListener { _, user in
            DispatchQueue.main.async {
                self.isLoggedIn = (user != nil)
                self.currentUsername = user?.displayName ?? "User\(Int.random(in: 1000...9999))"
                self.profileImageURL = user?.photoURL?.absoluteString ?? ""
            }
        }
    }
}
