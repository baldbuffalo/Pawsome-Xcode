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
    @State private var profileImageURL: String? = nil // ✅ store only Firebase URL

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
                    TabView {
                        HomeView(
                            isLoggedIn: $isLoggedIn,
                            currentUsername: $username,
                            profileImageURL: $profileImageURL,
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
                            profileImage: $profileImageURL // ✅ use string binding
                        )
                        .tabItem { Label("Profile", systemImage: "person.crop.circle") }
                    }
                    #if os(macOS)
                    .tabViewStyle(DefaultTabViewStyle()) // fixes TabContent issue on macOS
                    #endif
                }
            } else {
                LoginView(
                    isLoggedIn: $isLoggedIn,
                    username: $username,
                    profileImage: $profileImageURL // ✅ use String? for Firebase URL
                )
            }
        }
    }
}
