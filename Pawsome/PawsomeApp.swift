import SwiftUI

@main
struct PawsomeApp: App {
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    #elseif os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    #endif

    @State private var isLoggedIn: Bool = false
    @State private var username: String = "Guest"
    @State private var profileImage: PlatformImage? = nil // ✅ cross-platform image type

    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                NavigationStack {
                    TabView {
                        HomeView(
                            isLoggedIn: $isLoggedIn,
                            currentUsername: $username,
                            profileImage: $profileImage,
                            onPostCreated: {
                                print("New post created!")
                            }
                        )
                        .tabItem {
                            Label("Home", systemImage: "house")
                        }

                        ScanView(
                            selectedImage: .constant(nil),
                            username: username,
                            onPostCreated: { post in
                                print("🔥 New post: \(post.catName)")
                            }
                        )
                        .tabItem {
                            Label("Post", systemImage: "plus.app")
                        }

                        ProfileView(
                            isLoggedIn: $isLoggedIn,
                            currentUsername: $username,
                            profileImage: $profileImage
                        )
                        .tabItem {
                            Label("Profile", systemImage: "person.crop.circle")
                        }
                    }
                    #if os(macOS)
                    .tabViewStyle(DefaultTabViewStyle()) // fixes TabContent issue
                    #endif
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
