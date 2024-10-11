import SwiftUI
import SwiftData

@main
struct PawsomeApp: App {
    @State private var isLoggedIn: Bool = false
    @State private var username: String = ""
    @State private var profileImage: Image? = nil // Add @State for profileImage

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Item.self])
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
                // Pass all the required bindings, including profileImage
                LoginView(isLoggedIn: $isLoggedIn, username: $username, profileImage: $profileImage)
                    .modelContainer(sharedModelContainer)
            }
        }
    }
}
