import Foundation
import FirebaseCore
import FirebaseAppCheck

#if os(iOS)
import UIKit
import GoogleSignIn
typealias AppPlatformDelegate = UIApplicationDelegate
#elseif os(macOS)
import AppKit
typealias AppPlatformDelegate = NSApplicationDelegate
#endif

// MARK: - App Attest Provider Factory (iOS only)
#if os(iOS)
final class AppAttestProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        return AppAttestProvider(app: app)
    }
}
#endif

final class AppDelegate: NSObject, AppPlatformDelegate {

    override init() {
        super.init()

        // Configure Firebase once during initialization
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            #if os(iOS)
            print("🔥 Firebase configured (init - iOS)")

            // Set App Check provider
            AppCheck.setAppCheckProviderFactory(AppAttestProviderFactory())
            #elseif os(macOS)
            print("🔥 Firebase configured (init - macOS)")
            #endif
        }
    }

    // MARK: - iOS
    #if os(iOS)
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        // Configure Firebase again if needed (safe)
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            print("🔥 Firebase configured (iOS didFinishLaunching)")
        }
        return true
    }

    // For UIScene lifecycle (iOS 13+)
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        for context in URLContexts {
            _ = GIDSignIn.sharedInstance.handle(context.url)
        }
    }

    @available(iOS, introduced: 9.0, deprecated: 13.0, message: "Use scene(_:openURLContexts:) with UIScene lifecycle on iOS 13+")
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
    #endif

    // MARK: - macOS
    #if os(macOS)
    func applicationDidFinishLaunching(_ notification: Notification) {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            print("🔥 Firebase configured (macOS applicationDidFinishLaunching)")
        }
    }
    #endif
}
