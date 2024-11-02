#if canImport(UIKit)
import UIKit
import Firebase
import GoogleSignIn
import AVFoundation
import CoreData

class AppDelegate: NSObject, UIApplicationDelegate {
    var window: UIWindow?
    var photoOutput: AVCapturePhotoOutput? // Declare photoOutput

    // Core Data stack
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "YourModelName") // Replace with your model name
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure() // Initialize Firebase
        return true
    }

    // Handle URL opening for Google Sign-In
    func application(_ app: UIApplication, open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
    
    // Method to save the context
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
#endif
