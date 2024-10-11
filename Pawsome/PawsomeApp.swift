import SwiftUI
import SwiftData

@main
struct PawsomeApp: App {
    @State private var isLoggedIn: Bool = false
    @State private var username: String = "" // Store username with @State
    
    // Create a shared model container
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,  // Use the existing Item model
            // Add other models here if needed
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                HomeView(isLoggedIn: $isLoggedIn, currentUsername: $username)
                    .modelContainer(sharedModelContainer)
            } else {
                LoginView(isLoggedIn: $isLoggedIn, username: $username) // Pass the binding for username
                    .modelContainer(sharedModelContainer)
            }
        }
    }
}
