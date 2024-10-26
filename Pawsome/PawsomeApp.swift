import SwiftUI
import CoreData

@main
struct PawsomeApp: App {
    @State private var isLoggedIn: Bool = false
    @State private var username: String = ""
    @State private var profileImage: Image? = nil

    // Use the shared PersistenceController
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                HomeView(isLoggedIn: $isLoggedIn, currentUsername: $username, profileImage: $profileImage)
                    .environment(\.managedObjectContext, persistenceController.container.viewContext) // Pass the managed object context
            } else {
                LoginView(isLoggedIn: $isLoggedIn, username: $username, profileImage: $profileImage)
                    .environment(\.managedObjectContext, persistenceController.container.viewContext) // Pass the managed object context
            }
        }
    }
}
