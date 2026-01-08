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
        AppCheck.setAppCheckProviderFactory(AppCheckDebugProviderFactory())
        print("🔥 Firebase configured (iOS)")

        // 🔥 AdMob (NEW SDK)
        MobileAds.shared.start()
        print("🔥 AdMob initialized")

        // 🧪 DEBUG ONLY – enables Ad Inspector
        #if DEBUG
        MobileAds.shared.requestConfiguration.testDeviceIdentifiers = ["Simulator"]
        print("🧪 AdMob test device enabled")
        #endif

        return true
    }

    // Optional: handle Google Sign-In redirect URL on iOS
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
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

        // 🚫 AdMob not supported on macOS
    }

    // 🔑 Google Sign-In callback for macOS
    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            _ = GIDSignIn.sharedInstance.handle(url)
        }
    }
}
#endif
