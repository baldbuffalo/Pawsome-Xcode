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
                    // Pass username and profileImage as parameters
                    HomeView(currentUsername: username, profileImage: $profileImage)
                        .tabItem {
                            Label("Home", systemImage: "house")
                        }

                    // Pass capturedImage and videoURL
                    ScanView(capturedImage: $capturedImage, videoURL: $videoURL, username: username) { newPost in
                        addPost(newPost) // Call to add a new post
                    }
                    .tabItem {
                        Label("Post", systemImage: "plus.message")
                    }

                    // Pass the necessary parameters to ProfileView
                    ProfileView(isLoggedIn: $isLoggedIn, currentUsername: username, profileImage: $profileImage)
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
        // Add the logic to create a new post in Core Data
        let context = persistenceController.container.viewContext
        let post = CatPost(context: context)
        
        // Assuming `CatPost` has properties for username, imageData, etc.
        post.username = username // Set the username
        // Set other properties of the post (imageData, videoURL, etc.)
        
        saveContext() // Save the context after adding the post
    }

    private func saveContext() {
        do {
            try persistenceController.container.viewContext.save()
        } catch {
            let nsError = error as NSError
            print("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}
