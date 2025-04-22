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
    @State private var isLoadingImage: Bool = true  // Track if the profile image is still loading

    @StateObject private var profileView = ProfileView() // Global profile state

    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                // Wait for profile image to load
                if isLoadingImage {
                    ProgressView("Loading Profile...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                        .onAppear {
                            loadProfileImage()  // Load the profile image when the app starts
                        }
                } else {
                    TabView {
                        HomeView(
                            isLoggedIn: $isLoggedIn,
                            currentUsername: $username,
                            profileImage: $profileImage, // Pass as a binding
                            onPostCreated: { _ in
                                loadProfileImage() // Reload profile image after a post is created
                            }
                        )
                        .tabItem {
                            Label("Home", systemImage: "house")
                        }

                        ScanView(
                            selectedImage: .constant<PlatformImage?>(nil),
                            username: username,
                            onPostCreated: { _ in
                                loadProfileImage() // Reload profile image from ScanView
                            }
                        )
                        .tabItem {
                            Label("Post", systemImage: "plus.app")
                        }

                        // ProfileView remains, but without a tab item
                        ProfileView(
                            isLoggedIn: $isLoggedIn,
                            currentUsername: $username,
                            profileImage: $profileImage
                        )
                        .environmentObject(profileView)  // Pass ProfileView as an EnvironmentObject
                    }
                    .environmentObject(profileView)  // Make sure the ProfileView object is passed to all subviews
                }
            } else {
                LoginView(
                    isLoggedIn: $isLoggedIn,
                    username: $username,
                    profileImage: $profileImage // Pass the profile image to LoginView
                )
            }
        }
    }

    private func loadProfileImage() {
        // Ensure the username is available
        guard !username.isEmpty else {
            print("Username is empty. Cannot load profile image.")
            DispatchQueue.main.async {
                isLoadingImage = false  // Done loading even if there's no image
            }
            return
        }
        
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let profileImageRef = storageRef.child("profileImages/\(username).jpg")
        
        // Download up to 1 MB of data (adjust maxSize as needed)
        profileImageRef.getData(maxSize: 1 * 1024 * 1024) { data, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error fetching profile image: \(error.localizedDescription)")
                    self.profileImage = nil  // Ensure no corrupted image is shown
                } else if let data = data, let image = PlatformImage(data: data) {
                    self.profileImage = image
                }
                self.isLoadingImage = false  // Done loading
            }
        }
    }
}
