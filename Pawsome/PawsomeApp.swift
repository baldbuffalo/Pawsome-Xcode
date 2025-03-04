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
    @State private var selectedImage: Any? = nil
    
    @StateObject private var profileView = ProfileView() // Global profile state

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
                .environmentObject(profileView)
            } else {
                LoginView(
                    isLoggedIn: $isLoggedIn,
                    username: $username,
                    profileImage: profileImageBinding
                )
            }
        }
    }

    // Profile image binding (cross-platform)
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

    // Convert image to Data
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

    // Save post to Firebase Firestore
    private func savePostToFirebase(capturedImage: Any?, username: String) {
        guard let capturedImage = capturedImage else { return }
        
        let db = Firestore.firestore()
        let postRef = db.collection("posts").document()
        guard let finalImageData = imageData(from: capturedImage) else {
            print("Failed to process image")
            return
        }

        let newPost: [String: Any] = [
            "username": username,
            "timestamp": Timestamp(date: Date()),
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
