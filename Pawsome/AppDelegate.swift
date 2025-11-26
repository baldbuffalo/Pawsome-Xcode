import UIKit
import FirebaseCore
import FirebaseAppCheck
import GoogleSignIn

final class AppDelegate: NSObject, UIApplicationDelegate {

    override init() {
        super.init()
        // 🔥 Configure Firebase FIRST
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            print("🔥 Firebase configured (init)")
            // Set AppCheck provider
            AppCheck.setAppCheckProviderFactory(AppAttestProviderFactory())
        }
    }

    @objc func application(_ application: UIApplication,
                           didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Already configured in init(), safe to return true
        return true
    }

    @objc func application(_ app: UIApplication, open url: URL,
                           options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}

// MARK: - AppAttest Factory
final class AppAttestProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        return AppAttestProvider(app: app)
    }
}

