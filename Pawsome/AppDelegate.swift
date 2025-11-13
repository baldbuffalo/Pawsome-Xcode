import Foundation
import FirebaseCore
#if os(iOS)
import UIKit
typealias AppPlatformDelegate = UIApplicationDelegate
#elseif os(macOS)
import AppKit
typealias AppPlatformDelegate = NSApplicationDelegate
#endif

final class AppDelegate: NSObject, AppPlatformDelegate {
    static let shared = AppDelegate()

    #if os(iOS)
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        configureFirebase()
        return true
    }

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
    #elseif os(macOS)
    func applicationDidFinishLaunching(_ notification: Notification) {
        configureFirebase()
    }
    #endif

    private func configureFirebase() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            print("✅ Firebase configured in AppDelegate")
        }
    }
}
