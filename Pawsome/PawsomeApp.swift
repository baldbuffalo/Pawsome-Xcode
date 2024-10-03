import SwiftUI
import SwiftData

@main
struct PawsomeApp: App {
    @State private var isLoggedIn: Bool = false // Track login status

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,  // Use the existing Item model
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
                // Pass the binding of isLoggedIn to ContentView
                ContentView(isLoggedIn: $isLoggedIn)
            } else {
                // Pass the binding of isLoggedIn to LoginView
                LoginView(isLoggedIn: $isLoggedIn)
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
