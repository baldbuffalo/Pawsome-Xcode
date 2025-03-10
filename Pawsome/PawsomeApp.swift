import SwiftUI

@main
struct PawsomeApp: App {
    @State private var isLoggedIn: Bool = false
    @State private var username: String = ""
    @State private var profileImage: Any? = nil // Keep profile image state here

    @StateObject private var profileView = ProfileView() // Global profile state

    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                TabView {
                    // Only pass profile image where needed (HomeView and ProfileView)
                    HomeView(
                        isLoggedIn: $isLoggedIn,
                        currentUsername: $username,
                        profileImage: $profileImage // Pass it here
                    )
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }

                    ScanView(
                        selectedImage: .constant(nil), // No need for profile image here
                        username: username
                    )
                    .tabItem {
                        Label("Post", systemImage: "plus.app")
                    }

                    ProfileView(
                        isLoggedIn: $isLoggedIn,
                        currentUsername: $username,
                        profileImage: $profileImage // Pass it here
                    )
                    .tabItem {
                        Label("Profile", systemImage: "person.circle")
                    }
                }
                .environmentObject(profileView)
            } else {
                LoginView(
                    isLoggedIn: $isLoggedIn,
                    username: $username,
                    profileImage: $profileImage // Pass it to LoginView if needed
                )
            }
        }
    }
}
