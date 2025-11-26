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

    // Handle URL callbacks using UIScene lifecycle (iOS 13+)
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        for context in URLContexts {
            let url = context.url
            if GIDSignIn.sharedInstance.handle(url) {
                return
            }
            // Handle other URL types here if needed
        }
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
