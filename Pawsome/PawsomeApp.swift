import SwiftUI
import FirebaseStorage

// Use a cross-platform image type
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
    @State private var isLoadingImage: Bool = true         // Track if the profile image is still loading

    @StateObject private var profileViewModel = ProfileViewModel() // Renamed view model

    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                if isLoadingImage {
                    ProgressView("Loading Profile...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                        .onAppear {
                            loadProfileImage()
                        }
                } else {
                    TabView {
                        HomeView(
                            isLoggedIn: $isLoggedIn,
                            currentUsername: $username,
                            profileImage: $profileImage,
                            onPostCreated: {
                                loadProfileImage()
                            }
                        )
                        .tabItem {
                            Label("Home", systemImage: "house")
                        }

                        ScanView(
                            selectedImage: .constant(nil),
                            username: username,
                            onPostCreated: {
                                loadProfileImage()
                            }
                        )
                        .tabItem {
                            Label("Post", systemImage: "plus.app")
                        }

                        ProfileViewUI() // Updated: now uses the proper SwiftUI view
                            .environmentObject(profileViewModel)
                            .tabItem {
                                Label("Profile", systemImage: "person.crop.circle")
                            }
                    }
                    .environmentObject(profileViewModel)
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
        guard !username.isEmpty else {
            print("Username is empty. Cannot load profile image.")
            DispatchQueue.main.async {
                isLoadingImage = false
            }
            return
        }

        let storage = Storage.storage()
        let profileImageRef = storage.reference().child("profileImages/\(username).jpg")

        profileImageRef.getData(maxSize: 1 * 1024 * 1024) { data, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error fetching profile image: \(error.localizedDescription)")
                    self.profileImage = nil
                } else if let data = data, let image = PlatformImage(data: data) {
                    self.profileImage = image
                }
                self.isLoadingImage = false
            }
        }
    }
}
