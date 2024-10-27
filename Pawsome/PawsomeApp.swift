import SwiftUI
import CoreData

@main
struct PawsomeApp: App {
    @State private var isLoggedIn: Bool = false
    @State private var username: String = ""
    @State private var profileImage: Image? = nil

    // Shared PersistenceController instance for Core Data
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                HomeView(isLoggedIn: $isLoggedIn, currentUsername: $username, profileImage: $profileImage)
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
            } else {
                LoginView(isLoggedIn: $isLoggedIn, username: $username, profileImage: $profileImage)
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
            }
        }
    }
}
