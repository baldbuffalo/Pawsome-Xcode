import SwiftUI

@main
struct PawsomeApp: App {
    @State private var isLoggedIn: Bool = false
    @State private var username: String = ""
    @State private var profileImage: NSImage? = nil  // Using NSImage for macOS compatibility

    @StateObject private var profileView = ProfileView() // Global profile state

    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                TabView {
                    HomeView(
                        isLoggedIn: $isLoggedIn,
                        currentUsername: $username,
                        profileImage: $profileImage,
                        onPostCreated: {
                            // Handle post creation logic
                            print("Post created!")
                        }
                    )
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }

                    ScanView(
                        selectedImage: .constant(nil),
                        username: username,
                        onPostCreated: {
                            // Handle post creation logic from ScanView
                            print("Post created from ScanView!")
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
                        Label("Profile", systemImage: "person.circle")
                    }
                }
                .environmentObject(profileView)
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
