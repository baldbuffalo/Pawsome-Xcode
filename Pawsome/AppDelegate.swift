import Foundation
import FirebaseCore
#if os(iOS)
import UIKit
import GoogleSignIn
typealias AppPlatformDelegate = UIApplicationDelegate
#elseif os(macOS)
import AppKit
typealias AppPlatformDelegate = NSApplicationDelegate
#endif

final class AppDelegate: NSObject, AppPlatformDelegate {
    static let shared = AppDelegate()

    // Initialize Firebase immediately when AppDelegate is created
    override init() {
        super.init()
        configureFirebase()
    }

    // MARK: - iOS
    #if os(iOS)
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Firebase is already configured in init()
        return true
    }

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        // Handle Google Sign-In URL safely
        return GIDSignIn.sharedInstance.handle(url)
    }
    #elseif os(macOS)
    // MARK: - macOS
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Firebase is already configured in init()
    }
    #endif

    // MARK: - Firebase Configuration
    private func configureFirebase() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            print("✅ Firebase configured in AppDelegate init")
        }
    }
}
