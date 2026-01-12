import SwiftUI
import FirebaseCore

#if os(iOS)
import UIKit
import FirebaseAppCheck
import GoogleMobileAds
import GoogleSignIn

final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {

        // 🔥 Firebase
        FirebaseApp.configure()
        print("🔥 Firebase configured (iOS)")

        // 🔥 AdMob
        MobileAds.shared.start()
        print("🔥 AdMob initialized")

        return true
    }

    // 🔑 Google Sign-In callback (iOS)
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}
#endif

#if os(macOS)
import AppKit
import GoogleSignIn

final class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 🔥 Firebase
        FirebaseApp.configure()
        print("🔥 Firebase configured (macOS)")
    }

    // 🔑 Google Sign-In callback (macOS)
    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            _ = GIDSignIn.sharedInstance.handle(url)
        }
    }
}
#endif
