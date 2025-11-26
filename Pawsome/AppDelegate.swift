import Foundation
import FirebaseCore
import FirebaseAppCheck

#if os(iOS)
import UIKit
import GoogleSignIn
#elseif os(macOS)
import AppKit
#endif

// MARK: - App Attest Provider Factory (iOS only)
#if os(iOS)
final class AppAttestProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        return AppAttestProvider(app: app)
    }
}
#endif

#if os(iOS)
// MARK: - iOS AppDelegate
final class AppDelegate: NSObject, UIApplicationDelegate {

    override init() {
        super.init()
        // Configure Firebase once during initialization
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            print("🔥 Firebase configured (init - iOS)")
            // Set App Check provider
            AppCheck.setAppCheckProviderFactory(AppAttestProviderFactory())
        }
    }

    // UIApplicationDelegate
    @objc func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            print("🔥 Firebase configured (iOS didFinishLaunching)")
        }
        return true
    }

    // UIScene lifecycle (iOS 13+)
    @objc func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            print("🔥 Firebase configured (iOS scene openURLContexts)")
        }
        for context in URLContexts {
            _ = GIDSignIn.sharedInstance.handle(context.url)
        }
    }

    // Fallback for pre-Scene iOS
    @available(iOS, introduced: 9.0, deprecated: 13.0, message: "Use scene(_:openURLContexts:) with UIScene lifecycle on iOS 13+")
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}
#endif

#if os(macOS)
// MARK: - macOS AppDelegate
final class AppDelegate: NSObject, NSApplicationDelegate {

    override init() {
        super.init()
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            print("🔥 Firebase configured (init - macOS)")
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            print("🔥 Firebase configured (macOS applicationDidFinishLaunching)")
        }
    }
}
#endif
