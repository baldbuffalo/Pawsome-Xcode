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
    override init() {
        super.init()
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            #if os(iOS)
            print("🔥 Firebase configured (AppDelegate init - iOS)")
            #elseif os(macOS)
            print("🔥 Firebase configured (AppDelegate init - macOS)")
            #endif
        }
    }

    // MARK: - iOS
    #if os(iOS)
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        // Configure Firebase once at app launch
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            print("🔥 Firebase configured (iOS didFinishLaunching)")
        }
        return true
    }

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        // Handle Google Sign-In callback URLs
        return GIDSignIn.sharedInstance.handle(url)
    }
    #endif

    // MARK: - macOS
    #if os(macOS)
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Configure Firebase once at app launch
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            print("🔥 Firebase configured (macOS applicationDidFinishLaunching)")
        }
    }
    #endif
}
