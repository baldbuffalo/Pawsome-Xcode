import SwiftUI
import CoreData

@main
struct PawsomeApp: App {
    @State private var isLoggedIn: Bool = false
    @State private var username: String = ""
    @State private var profileImageData: Data? = nil
    @State private var selectedImage: UIImage? = nil

    // Shared PersistenceController instance for Core Data
    let persistenceController = PersistenceController.shared

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
                                    return UIImage(data: data)
                                }
                                return nil
                            },
                            set: { newImage in
                                profileImageData = newImage?.jpegData(compressionQuality: 1.0)
                            }
                        )
                    )
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)

                    ScanView(
                        capturedImage: $selectedImage,
                        username: username,
                        onPostCreated: { catPost in
                            savePostToCoreData(capturedImage: selectedImage, username: username)
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
                                    return UIImage(data: data)
                                }
                                return nil
                            },
                            set: { newImage in
                                profileImageData = newImage?.jpegData(compressionQuality: 1.0)
                            }
                        )
                    )
                    .tabItem {
                        Label("Profile", systemImage: "person.circle")
                    }
                }
            } else {
                LoginView(
                    isLoggedIn: $isLoggedIn,
                    username: $username,
                    profileImage: Binding<UIImage?>(
                        get: {
                            if let data = profileImageData {
                                return UIImage(data: data)
                            }
                            return nil
                        },
                        set: { newImage in
                            profileImageData = newImage?.jpegData(compressionQuality: 1.0)
                        }
                    )
                )
            }
        }
    }

    // Function to save post data to Core Data
    private func savePostToCoreData(capturedImage: UIImage?, username: String) {
        let context = persistenceController.container.viewContext
        let newPost = CatPost(context: context) // Make sure 'CatPost' is set up in your Core Data model
        newPost.username = username
        newPost.timestamp = Date()

        // Convert UIImage to Data for Core Data
        if let image = capturedImage, let imageData = image.jpegData(compressionQuality: 1.0) {
            newPost.imageData = imageData
        }

        do {
            try context.save()
        } catch {
            print("Failed to save post: \(error.localizedDescription)")
        }
    }
}
