import SwiftUI
import FirebaseFirestore
import FirebaseAuth

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

@main
struct PawsomeApp: App {
    @State private var isLoggedIn: Bool = false
    @State private var username: String = ""
    @State private var profileImageData: Data? = nil
    @State private var selectedImage: Any? = nil // Changed to Any for platform-specific image types
    
    @StateObject private var profileView = ProfileView() // Create ProfileView as @StateObject
    
    private let db = Firestore.firestore() // Firestore instance

    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                TabView {
                    // Home View
                    HomeView(
                        isLoggedIn: $isLoggedIn,
                        currentUsername: $username,
                        profileImage: profileImageBinding
                    )
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }

                    // Scan View
                    ScanView(
                        capturedImage: $selectedImage,
                        username: username,
                        onPostCreated: { catPost in
                            savePostToFirebase(capturedImage: selectedImage, username: username)
                        }
                    )
                    .tabItem {
                        Label("Post", systemImage: "plus.app")
                    }

                    // Profile View
                    ProfileView(
                        isLoggedIn: $isLoggedIn,
                        currentUsername: $username,
                        profileImage: profileImageBinding
                    )
                    .tabItem {
                        Label("Profile", systemImage: "person.circle")
                    }
                }
                .environmentObject(profileView) // Inject ProfileView as an environment object
            } else {
                LoginView(
                    isLoggedIn: $isLoggedIn,
                    username: $username,
                    profileImage: profileImageBinding
                )
            }
        }
    }

    // Helper to generate a Binding for profile image across platforms
    private var profileImageBinding: Binding<Any?> {
        Binding<Any?>(
            get: {
                if let data = profileImageData {
                    #if os(iOS)
                    return UIImage(data: data)
                    #elseif os(macOS)
                    return NSImage(data: data)
                    #endif
                }
                return nil
            },
            set: { newImage in
                profileImageData = imageData(from: newImage)
            }
        )
    }

    // Helper function to convert image to Data
    private func imageData(from image: Any?) -> Data? {
        #if os(iOS)
        if let uiImage = image as? UIImage {
            return uiImage.jpegData(compressionQuality: 1.0)
        }
        #elseif os(macOS)
        if let nsImage = image as? NSImage {
            return nsImage.tiffRepresentation
        }
        #endif
        return nil
    }

    // Function to save a post to Firebase Firestore for iOS and macOS
    private func savePostToFirebase(capturedImage: Any?, username: String) {
        guard let capturedImage = capturedImage else { return }
        
        let postRef = db.collection("posts").document() // Create a new post document
        guard let finalImageData = imageData(from: capturedImage) else {
            print("Failed to process image")
            return
        }

        let newPost: [String: Any] = [
            "username": username,
            "timestamp": Date(),
            "imageData": finalImageData
        ]
        
        postRef.setData(newPost) { error in
            if let error = error {
                print("Failed to save post: \(error.localizedDescription)")
            } else {
                print("Post saved successfully!")
            }
        }
    }
}
