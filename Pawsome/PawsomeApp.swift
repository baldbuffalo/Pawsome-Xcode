import SwiftUI

@main
struct PawsomeApp: App {
    @State private var isLoggedIn: Bool = false
    @State private var username: String = ""
    @State private var profileImageData: Data? = nil
    @State private var selectedImage: Any? = nil
    
    @StateObject private var profileView = ProfileView() // Global profile state

    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                TabView {
                    HomeView(
                        isLoggedIn: $isLoggedIn,
                        currentUsername: $username,
                        profileImage: profileImageBinding // 🔥 FIXED
                    )
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }

                    ScanView(
                        selectedImage: $selectedImage,
                        username: username
                    )
                    .tabItem {
                        Label("Post", systemImage: "plus.app")
                    }

                    ProfileView(
                        isLoggedIn: $isLoggedIn,
                        currentUsername: $username,
                        profileImage: profileImageBinding // 🔥 FIXED
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
                    profileImage: profileImageBinding // 🔥 FIXED
                )
            }
        }
    }

    // 🔥 FIXED: Convert profileImageData (Data?) to Any?
    private var profileImageBinding: Binding<Any?> {
        Binding<Any?>(
            get: {
                profileImageData // No conversion needed here
            },
            set: { newImage in
                if let data = newImage as? Data {
                    profileImageData = data
                } else {
                    profileImageData = nil
                }
            }
        )
    }
}
