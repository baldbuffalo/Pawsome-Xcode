import SwiftUI
import FirebaseCore

#if os(iOS)
import UIKit
import FirebaseAppCheck
import GoogleMobileAds

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {

        FirebaseApp.configure()
        AppCheck.setAppCheckProviderFactory(AppCheckDebugProviderFactory())
        print("🔥 Firebase configured (iOS)")

        // ✅ NEW SDK NAME
        MobileAds.shared.start()

        print("🔥 AdMob initialized")
        return true
    }
}
#endif

#if os(macOS)
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        FirebaseApp.configure()
        print("🔥 Firebase configured (macOS)")
    }
}
#endif
