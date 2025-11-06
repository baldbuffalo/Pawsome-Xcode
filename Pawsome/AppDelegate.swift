import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import GoogleSignIn

#if os(iOS)
import UIKit
typealias AppPlatformDelegate = UIApplicationDelegate
#elseif os(macOS)
import AppKit
typealias AppPlatformDelegate = NSApplicationDelegate
#endif

// MARK: - AppDelegate
final class AppDelegate: NSObject, AppPlatformDelegate {
    static let shared = AppDelegate()

    // MARK: - Launch
    #if os(iOS)
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        initializeApp()
        return true
    }
    #elseif os(macOS)
    func applicationDidFinishLaunching(_ notification: Notification) {
        initializeApp()
    }
    #endif

    // MARK: - Firebase Init
    private func initializeApp() {
        guard FirebaseApp.app() == nil else { return }
        FirebaseApp.configure()
        print("✅ Firebase configured successfully")
        setupServices()
    }

    // MARK: - Extra Services
    private func setupServices() {
        // 🔧 Add analytics, notifications, or any custom setup here
        print("⚙️ Services initialized")
    }

    // MARK: - Google Sign-In (iOS only)
    #if os(iOS)
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        GIDSignIn.sharedInstance.handle(url)
    }
    #endif

    // MARK: - macOS URL Handling
    #if os(macOS)
    func application(_ application: NSApplication, open urls: [URL]) {
        urls.forEach { print("🌐 Opened URL: \($0.absoluteString)") }
    }
    #endif
}
