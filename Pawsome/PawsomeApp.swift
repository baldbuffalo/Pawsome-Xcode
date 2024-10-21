import SwiftUI
import SwiftData

@main
struct PawsomeApp: App {
    @State private var isLoggedIn: Bool = false
    @State private var username: String = ""
    @State private var profileImage: Image? = nil

    var sharedModelContainer: ModelContainer = {
        // Use CatPost instead of UserPost
        let schema = Schema([CatPost.self])
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
                // Pass profileImage to HomeView
                HomeView(isLoggedIn: $isLoggedIn, currentUsername: $username, profileImage: $profileImage)
                    .modelContainer(sharedModelContainer)
            } else {
                // Pass all the required bindings, including profileImage
                LoginView(isLoggedIn: $isLoggedIn, username: $username, profileImage: $profileImage)
                    .modelContainer(sharedModelContainer)
            }
        }
    }
}
