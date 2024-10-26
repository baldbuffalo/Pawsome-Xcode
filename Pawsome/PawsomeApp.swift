import SwiftUI
import CoreData

@main
struct PawsomeApp: App {
    @State private var isLoggedIn: Bool = false
    @State private var username: String = ""
    @State private var profileImage: Image? = nil

    // Create the Core Data stack
    let persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "CatPostModel") // Ensure this matches your .xcdatamodeld file name
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()

    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                HomeView(isLoggedIn: $isLoggedIn, currentUsername: $username, profileImage: $profileImage)
                    .environment(\.managedObjectContext, persistentContainer.viewContext) // Pass the managed object context
            } else {
                LoginView(isLoggedIn: $isLoggedIn, username: $username, profileImage: $profileImage)
                    .environment(\.managedObjectContext, persistentContainer.viewContext) // Pass the managed object context
            }
        }
    }
}
