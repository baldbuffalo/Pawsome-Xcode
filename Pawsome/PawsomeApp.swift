import SwiftUI

@main
struct PawsomeApp: App {
    @State private var isLoggedIn: Bool = false
    @State private var username: String = ""
    @State private var profileImage: PlatformImage? = nil  // Load and store profile image

    @StateObject private var profileView = ProfileView() // Global profile state

    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                TabView {
                    HomeView(
                        isLoggedIn: $isLoggedIn,
                        currentUsername: $username,
                        profileImage: $profileImage, // Pass as a binding
                        onPostCreated: {
                            loadProfileImage() // Reload profile image after a post is created
                        }
                    )
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }

                    ScanView(
                        selectedImage: .constant(nil),
                        username: username,
                        onPostCreated: {
                            loadProfileImage() // Reload profile image from ScanView
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
                .onAppear {
                    loadProfileImage() // Load the profile image when the app starts
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

    private func loadProfileImage() {
        // Load the user's profile picture from storage or database
        // This is just an example; replace with your actual loading logic
        DispatchQueue.global().async {
            if let image = fetchProfileImageFromDatabase() {
                DispatchQueue.main.async {
                    self.profileImage = image
                }
            }
        }
    }
}
