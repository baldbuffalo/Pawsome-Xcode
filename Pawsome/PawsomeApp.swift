import SwiftUI
import CoreData

@main
struct PawsomeApp: App {
    @State private var isLoggedIn: Bool = false
    @State private var username: String = ""
    @State private var profileImage: Image? = nil
    @State private var capturedImage: UIImage? = nil
    @State private var videoURL: URL? = nil

    // Shared PersistenceController instance for Core Data
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                TabView {
                    // HomeView: Pass username and profileImage as parameters
                    HomeView(currentUsername: username, profileImage: $profileImage)
                        .tabItem {
                            Label("Home", systemImage: "house")
                        }

                    // ScanView: Pass capturedImage, videoURL, username, and the closure for onPostCreated
                    ScanView(
                        capturedImage: $capturedImage,
                        videoURL: $videoURL,
                        username: username,
                        onPostCreated: { newPost in
                            addPost(newPost) // Call to add a new post
                        },
                        selectedImageForForm: $capturedImage // Pass binding directly
                    )
                    .tabItem {
                        Label("Post", systemImage: "camera") // Camera icon
                    }

                    // ProfileView: Pass the necessary parameters
                    ProfileView(isLoggedIn: $isLoggedIn, currentUsername: $username, profileImage: $profileImage)
                        .tabItem {
                            Label("Profile", systemImage: "person")
                        }
                }
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
            } else {
                // Login screen when not logged in
                LoginView(isLoggedIn: $isLoggedIn, username: $username, profileImage: $profileImage)
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
            }
        }
    }

    private func addPost(_ newPost: CatPost) {
        // Logic to create a new post in Core Data
        let context = persistenceController.container.viewContext
        let post = CatPost(context: context)
        
        // Set properties for the new post
        post.username = username
        post.timestamp = Date() // Assuming you want to add a timestamp
        if let imageData = newPost.imageData {
            post.imageData = imageData // Set imageData if available
        }
        if let videoURLString = newPost.videoURL {
            post.videoURL = videoURLString // Set videoURL if available
        }
        
        saveContext() // Save the context after adding the post
    }

    private func saveContext() {
        do {
            try persistenceController.container.viewContext.save()
        } catch {
            let nsError = error as NSError
            print("Unresolved error \(nsError), \(nsError.userInfo)")
            // Handle error appropriately (e.g., show an alert to the user)
        }
    }
}
