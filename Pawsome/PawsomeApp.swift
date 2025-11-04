import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

@main
struct PawsomeApp: App {
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    #elseif os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    #endif

    @State private var isLoggedIn: Bool
    @State private var username: String
    @State private var profileImageURL: String? // Firebase URL string, not PlatformImage

    init() {
        // Check if the user already logged in previously
        let loggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
        let savedUsername = UserDefaults.standard.string(forKey: "username") ?? "Guest"
        let savedProfileURL = UserDefaults.standard.string(forKey: "profileImageURL")
        _isLoggedIn = State(initialValue: loggedIn)
        _username = State(initialValue: savedUsername)
        _profileImageURL = State(initialValue: savedProfileURL)
    }

    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                // Skip login and go straight to Home
                NavigationStack {
                    TabView {
                        HomeView(
                            isLoggedIn: $isLoggedIn,
                            currentUsername: $username,
                            profileImage: .constant(nil), // Home doesn't need actual image
                            onPostCreated: { print("🔥 New post!") }
                        )
                        .tabItem { Label("Home", systemImage: "house") }

                        ScanView(
                            selectedImage: .constant(nil),
                            username: username,
                            onPostCreated: { post in print("📸 New post: \(post.catName)") }
                        )
                        .tabItem { Label("Post", systemImage: "plus.app") }

                        ProfileView(
                            isLoggedIn: $isLoggedIn,
                            currentUsername: $username,
                            profileImage: $profileImageURL // String URL from Firebase
                        )
                        .tabItem { Label("Profile", systemImage: "person.crop.circle") }
                    }
                }
            } else {
                // New user or logged out
                LoginView(
                    isLoggedIn: $isLoggedIn,
                    username: $username,
                    profileImage: .constant(nil) // PlatformImage only for login
                )
            }
        }
    }
}
