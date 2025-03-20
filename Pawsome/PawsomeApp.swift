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
                            profileImage: $profileImage // Pass the image to ProfileView
                        )
                        .tabItem {
                            Label("Profile", systemImage: "person.circle")
                        }
                    }
                    .environmentObject(profileView)
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
        // Ensure the username is available (otherwise, you may not have a valid path)
        guard !username.isEmpty else {
            print("Username is empty. Cannot load profile image.")
            isLoadingImage = false  // Done loading even if there's no image
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
                    self.isLoadingImage = false  // Done loading
                }
            } else {
                DispatchQueue.main.async {
                    self.isLoadingImage = false  // Done loading even if there's no image
                }
            }
        }
    }
}
public protocol EquatableBytes: Equatable {
    
}