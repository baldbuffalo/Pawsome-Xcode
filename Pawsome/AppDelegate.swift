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

    // MARK: - Init (runs before platform-specific app launch)
    override init() {
        super.init()
        configureFirebaseIfNeeded(source: "init")
    }

    // MARK: - Firebase Config Helper
    private func configureFirebaseIfNeeded(source: String) {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            #if os(iOS)
            print("🔥 Firebase configured (\(source) - iOS)")
            #elseif os(macOS)
            print("🔥 Firebase configured (\(source) - macOS)")
            #endif
        }
    }

    // MARK: - iOS Lifecycle
    #if os(iOS)
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        configureFirebaseIfNeeded(source: "didFinishLaunching")
        return true
    }

    // iOS Google Sign-In URL handler (UIScene-based)
    func scene(
        _ scene: UIScene,
        openURLContexts URLContexts: Set<UIOpenURLContext>
    ) {
        for context in URLContexts {
            let url = context.url
            if GIDSignIn.sharedInstance.handle(url) {
                return
            }
            // (Optional) handle other URLs here
        }
    }
    #endif

    // MARK: - macOS Lifecycle
    #if os(macOS)
    func applicationDidFinishLaunching(_ notification: Notification) {
        configureFirebaseIfNeeded(source: "applicationDidFinishLaunching")
    }
    #endif
}
