#if canImport(UIKit)
import UIKit
import Firebase
import FirebaseAppCheck
import GoogleSignIn
import AVFoundation
import CoreData

class AppDelegate: NSObject, UIApplicationDelegate {
    var window: UIWindow?
    var photoOutput: AVCapturePhotoOutput?

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "CatPostModel")
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()

    // Computed property to decide if App Check should be enabled
    var enableAppCheck: Bool {
        #if targetEnvironment(macCatalyst)
        return false
        #elseif targetEnvironment(simulator)
        return true  // Enable debug App Check on simulator for testing
        #else
        return UIDevice.current.userInterfaceIdiom == .phone || UIDevice.current.userInterfaceIdiom == .pad
        #endif
    }

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()

        if enableAppCheck {
            #if targetEnvironment(simulator)
            print("✅ Enabling Debug App Check Provider (Simulator)")
            AppCheck.setAppCheckProviderFactory(DebugAppCheckProviderFactory())
            #else
            print("✅ Enabling App Attest Provider (Real iOS device)")
            let providerFactory = AppAttestProviderFactory()
            AppCheck.setAppCheckProviderFactory(providerFactory)
            #endif
        } else {
            print("🔕 Skipping App Check on this platform")
        }

        return true
    }

    func application(_ app: UIApplication, open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }

    func saveContext() {
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

#elseif canImport(AppKit)
import AppKit
import Firebase

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        FirebaseApp.configure()
        print("🔕 Skipping App Check: macOS does not support it")
        // No AppCheck on macOS
    }
}
#endif
