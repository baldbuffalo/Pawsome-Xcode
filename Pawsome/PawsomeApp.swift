import SwiftUI

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
    @State private var comments: [Comment] = [] // Array to store comments
    @State private var commentText: String = "" // To hold the text of the comment
    
    @StateObject private var profileView = ProfileView() // Create ProfileView as @StateObject

    #if os(iOS)
    @State private var selectedImage: UIImage? = nil
    #elseif os(macOS)
    @State private var selectedImage: NSImage? = nil
    #endif

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
                                    return NSImage(data: data) as? UIImage
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
                        username: username
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
                                    return NSImage(data: data) as? UIImage
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
                        commentText: $commentText
                    )
                    .tabItem {
                        Label("Comments", systemImage: "message")
                    }
                }
                .environmentObject(profileView) // Inject ProfileView as an environment object here
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
                                return NSImage(data: data) as? UIImage
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
}
