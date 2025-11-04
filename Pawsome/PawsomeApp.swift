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
    @State private var profileImageURL: String? = nil // Store URL from Firebase

    init() {
        let savedUsername = UserDefaults.standard.string(forKey: "username") ?? "Guest"
        let loggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
        let savedProfileURL = UserDefaults.standard.string(forKey: "profileImageURL")
        _username = State(initialValue: savedUsername)
        _isLoggedIn = State(initialValue: loggedIn)
        _profileImageURL = State(initialValue: savedProfileURL)
    }

    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                NavigationStack {
                    Group { // Fix TabContent conformance
                        TabView {
                            HomeView(
                                isLoggedIn: $isLoggedIn,
                                currentUsername: $username,
                                profileImage: .constant(nil), // Home doesn’t need URL for now
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
                                profileImageURL: $profileImageURL
                            )
                            .tabItem { Label("Profile", systemImage: "person.crop.circle") }
                        }
                    }
                }
            } else {
                LoginView(
                    isLoggedIn: $isLoggedIn,
                    username: $username,
                    profileImage: .constant(nil)
                )
            }
        }
    }
}

// MARK: - AppDelegate

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}
