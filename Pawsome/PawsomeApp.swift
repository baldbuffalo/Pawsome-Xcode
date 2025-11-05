import SwiftUI
import Firebase

@main
struct PawsomeApp: App {
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    #elseif os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    #endif

    @State private var isLoggedIn = false
    @State private var currentUsername: String = ""
    @State private var profileImageURL: String = ""

    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                TabView {
                    HomeView(
                        isLoggedIn: $isLoggedIn,
                        currentUsername: $currentUsername,
                        profileImageURL: $profileImageURL,
                        onPostCreated: { print("🔥 Post created!") }
                    )
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }

                    ProfileView(
                        isLoggedIn: $isLoggedIn,
                        currentUsername: $currentUsername,
                        profileImageURL: $profileImageURL
                    )
                    .tabItem {
                        Label("Profile", systemImage: "person.fill")
                    }
                }
            } else {
                LoginView(
                    isLoggedIn: $isLoggedIn,
                    currentUsername: $currentUsername,
                    profileImageURL: $profileImageURL
                )
            }
        }
    }
}
