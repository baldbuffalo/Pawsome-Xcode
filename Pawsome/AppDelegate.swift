import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - AppDelegate
class AppDelegate: NSObject {
    
    // Shared instance (optional, if you wanna access globally)
    static let shared = AppDelegate()
    
    // Firebase setup
    func setupFirebase() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            print("✅ Firebase configured")
        }
    }
    
    // Additional setup for notifications or other services can go here
    func setupServices() {
        // e.g., Push Notifications, Analytics, etc.
    }
}

#if os(iOS)
extension AppDelegate: UIApplicationDelegate {
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        setupFirebase()
        setupServices()
        return true
    }
    
    // Handle URL for Google Sign-In / other auth methods
    func application(_ app: UIApplication, open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // Google Sign-In URL handling
        return GIDSignIn.sharedInstance.handle(url)
    }
}

#elseif os(macOS)
extension AppDelegate: NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupFirebase()
        setupServices()
    }
    
    // Optional: handle open URL or other macOS-specific app events
    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            print("Opened URL: \(url.absoluteString)")
        }
    }
}
#endif
