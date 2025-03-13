import SwiftUI
import FirebaseStorage

// Use a cross-platform image type.
#if os(macOS)
import AppKit
typealias PlatformImage = NSImage
#else
import UIKit
typealias PlatformImage = UIImage
#endif

@main
struct PawsomeApp: App {
    @State private var isLoggedIn: Bool = false
    @State private var username: String = ""
    @State private var profileImage: PlatformImage? = nil  // Holds the loaded profile image

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
                            loadProfileImage() // Reload the profile image after a post is created
                        }
                    )
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }

                    ScanView(
                        selectedImage: .constant(nil),
                        username: username,
                        onPostCreated: {
                            loadProfileImage() // Reload the profile image from ScanView
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
        // Ensure the username is available (otherwise, you may not have a valid path)
        guard !username.isEmpty else {
            print("Username is empty. Cannot load profile image.")
            return
        }
        
        let storage = Storage.storage()
        let storageRef = storage.reference()
        // Adjust the storage path according to your Firebase Storage structure.
        let profileImageRef = storageRef.child("profileImages/\(username).jpg")
        
        // Download up to 1 MB of data (adjust maxSize as needed)
        profileImageRef.getData(maxSize: 1 * 1024 * 1024) { data, error in
            if let error = error {
                print("Error fetching profile image: \(error.localizedDescription)")
            } else if let data = data,
                      let image = PlatformImage(data: data) {
                DispatchQueue.main.async {
                    self.profileImage = image
                }
            }
        }
    }
}
