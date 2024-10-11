import SwiftUI
import SwiftData

@main
struct PawsomeApp: App {
    @State private var isLoggedIn: Bool = false // Track login status
    @State private var username: String = "" // Use @State to store username
    
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
            // Use @ViewBuilder to conditionally return different views
            if isLoggedIn {
                HomeView(isLoggedIn: $isLoggedIn, currentUsername: $username) // Pass the binding for username
                    .modelContainer(sharedModelContainer) // Set the model container for the HomeView
            } else {
                LoginView(isLoggedIn: $isLoggedIn, username: $username) // Pass the binding for username to LoginView
                    .modelContainer(sharedModelContainer) // Set the model container for the LoginView
            }
        }
    }
}
