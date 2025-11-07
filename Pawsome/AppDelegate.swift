import SwiftUI
import FirebaseCore
import FirebaseAuth
import GoogleSignIn

#if os(iOS)
import UIKit
typealias AppPlatformDelegate = UIApplicationDelegate
#elseif os(macOS)
import AppKit
typealias AppPlatformDelegate = NSApplicationDelegate
#endif

final class AppDelegate: NSObject, AppPlatformDelegate {
    static let shared = AppDelegate()

    // MARK: - Launch
    #if os(iOS)
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        configureFirebase()
        return true
    }
    #elseif os(macOS)
    func applicationDidFinishLaunching(_ notification: Notification) {
        configureFirebase()
    }
    #endif

    // MARK: - Firebase config
    private func configureFirebase() {
        guard FirebaseApp.app() == nil else { return }
        FirebaseApp.configure()
        print("✅ Firebase configured")
    }

    // MARK: - Google Sign-In (iOS)
    #if os(iOS)
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
    #endif

    // MARK: - macOS URL Handling
    #if os(macOS)
    func application(_ application: NSApplication, open urls: [URL]) {
        urls.forEach { print("🌐 Opened URL: \($0.absoluteString)") }
    }
    #endif
}
