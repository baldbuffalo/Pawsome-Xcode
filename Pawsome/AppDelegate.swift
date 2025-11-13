import SwiftUI
import FirebaseCore
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

    #if os(iOS)
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            print("✅ Firebase configured in AppDelegate (iOS)")
        }
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
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            print("✅ Firebase configured in AppDelegate (macOS)")
        }
    }
    #endif
}
