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
    @State private var selectedImage: UIImage? = nil
    @State private var comments: [Comment] = [] // Array to store comments
    @State private var commentText: String = "" // To hold the text of the comment

    private let db = Firestore.firestore() // Firestore instance

    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                TabView {
                    HomeView(
                        isLoggedIn: $isLoggedIn,
                        currentUsername: $username,
                        profileImage: Binding<UIImage?>(
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
                                #if os(iOS)
                                profileImageData = newImage?.jpegData(compressionQuality: 1.0)
                                #elseif os(macOS)
                                profileImageData = newImage?.tiffRepresentation
                                #endif
                            }
                        )
                    )
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }

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

                    ProfileView(
                        isLoggedIn: $isLoggedIn,
                        currentUsername: $username,
                        profileImage: Binding<UIImage?>(
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
                                #if os(iOS)
                                profileImageData = newImage?.jpegData(compressionQuality: 1.0)
                                #elseif os(macOS)
                                profileImageData = newImage?.tiffRepresentation
                                #endif
                            }
                        )
                    )
                    .tabItem {
                        Label("Profile", systemImage: "person.circle")
                    }

                    // Comments View
                    CommentsView(
                        comments: $comments,  // Your existing comments array binding
                        commentText: $commentText,
                        saveComment: saveCommentToFirebase(postId: "samplePostId") // Pass postId dynamically
                    )
                    .tabItem {
                        Label("Comments", systemImage: "message")
                    }
                }
            } else {
                LoginView(
                    isLoggedIn: $isLoggedIn,
                    username: $username,
                    profileImage: Binding<UIImage?>(
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
                            #if os(iOS)
                            profileImageData = newImage?.jpegData(compressionQuality: 1.0)
                            #elseif os(macOS)
                            profileImageData = newImage?.tiffRepresentation
                            #endif
                        }
                    )
                )
            }
        }
    }

    // Function to save a post to Firebase Firestore
    private func savePostToFirebase(capturedImage: UIImage?, username: String) {
        guard let capturedImage = capturedImage else { return }
        let postRef = db.collection("posts").document() // Create a new post document
        
        let newPost = [
            "username": username,
            "timestamp": Date(),
            "imageData": capturedImage.jpegData(compressionQuality: 1.0) as Any
        ] as [String: Any]
        
        postRef.setData(newPost) { error in
            if let error = error {
                print("Failed to save post: \(error.localizedDescription)")
            } else {
                print("Post saved successfully!")
            }
        }
    }
    
    // Function to save a comment to Firebase Firestore
    private func saveCommentToFirebase(postId: String) {
        guard !commentText.isEmpty else { return }

        let newComment = [
            "postId": postId,
            "commentText": commentText,
            "username": username,
            "timestamp": Date()
        ] as [String: Any]

        // Save the comment in the 'comments' collection
        db.collection("comments").addDocument(data: newComment) { error in
            if let error = error {
                print("Failed to save comment: \(error.localizedDescription)")
            } else {
                print("Comment saved successfully!")
                commentText = "" // Clear the comment field after saving
            }
        }
    }
}
