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
        configureFirebase()
    }

    // MARK: - Firebase Setup
    private func configureFirebase() {
        guard FirebaseApp.app() == nil else { return }
        FirebaseApp.configure()
        print("🔥 Firebase configured (AppDelegate init)")
    }

    // MARK: - iOS
    #if os(iOS)
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        true
    }

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        GIDSignIn.sharedInstance.handle(url)
    }
    #endif

    // MARK: - macOS
    #if os(macOS)
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Already configured in init
    }
    #endif
}
