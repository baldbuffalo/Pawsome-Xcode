import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

@main
struct PawsomeApp: App {
    // 🔥 Handles both iOS + macOS AppDelegate automatically
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    #elseif os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    #endif

    // MARK: - App State
    @State private var isLoggedIn: Bool
    @State private var username: String
    @State private var profileImageURL: String? = nil // Firebase image URL (not image obj)

    // MARK: - Init
    init() {
        let savedUsername = UserDefaults.standard.string(forKey: "username") ?? "Guest"
        let loggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
        let savedProfileURL = UserDefaults.standard.string(forKey: "profileImageURL")

        _username = State(initialValue: savedUsername)
        _isLoggedIn = State(initialValue: loggedIn)
        _profileImageURL = State(initialValue: savedProfileURL)
    }

    // MARK: - App Body
    var body: some Scene {
        WindowGroup {
            Group {
                if isLoggedIn {
                    NavigationStack {
                        VStack {
                            TabView {
                                // 🏠 Home Tab
                                HomeView(
                                    isLoggedIn: $isLoggedIn,
                                    currentUsername: $username,
                                    profileImageURL: $profileImageURL,
                                    onPostCreated: { print("🔥 New post!") }
                                )
                                .tabItem {
                                    Label("Home", systemImage: "house")
                                }

                                // 📸 Post Tab
                                ScanView(
                                    selectedImage: .constant(nil),
                                    username: username,
                                    onPostCreated: { post in
                                        print("📸 New post: \(post.catName)")
                                    }
                                )
                                .tabItem {
                                    Label("Post", systemImage: "plus.app")
                                }

                                // 👤 Profile Tab
                                ProfileView(
                                    isLoggedIn: $isLoggedIn,
                                    currentUsername: $username,
                                    profileImage: $profileImageURL
                                )
                                .tabItem {
                                    Label("Profile", systemImage: "person.crop.circle")
                                }
                            }
                            #if os(macOS)
                            .tabViewStyle(DefaultTabViewStyle()) // 💻 Fixes TabContent bug on macOS
                            #endif
                        }
                    }
                } else {
                    // 🔐 Login View for new/unauth users
                    LoginView(
                        isLoggedIn: $isLoggedIn,
                        username: $username,
                        profileImage: $profileImageURL
                    )
                }
            }
        }
    }
}
