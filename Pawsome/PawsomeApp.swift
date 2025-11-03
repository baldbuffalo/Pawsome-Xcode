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
    @State private var profileImage: PlatformImage? = nil // ✅ cross-platform image type

    init() {
        let savedUsername = UserDefaults.standard.string(forKey: "username") ?? "Guest"
        let loggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
        _username = State(initialValue: savedUsername)
        _isLoggedIn = State(initialValue: loggedIn)
    }

    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                NavigationStack {
                    TabView {
                        HomeView(
                            isLoggedIn: $isLoggedIn,
                            currentUsername: $username,
                            profileImage: $profileImage,
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
                            profileImage: $profileImage
                        )
                        .tabItem { Label("Profile", systemImage: "person.crop.circle") }
                    }
                }
            } else {
                LoginView(
                    isLoggedIn: $isLoggedIn,
                    username: $username,
                    profileImage: $profileImage
                )
            }
        }
    }
}
