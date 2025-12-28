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

        // 🔥 Firebase
        FirebaseApp.configure()
        AppCheck.setAppCheckProviderFactory(AppCheckDebugProviderFactory())
        print("🔥 Firebase configured (iOS)")

        // 🔥 AdMob (NEW SDK)
        MobileAds.shared.start()
        print("🔥 AdMob initialized")

        // 🧪 DEBUG ONLY – enables Ad Inspector
        #if DEBUG
        MobileAds.shared.requestConfiguration.testDeviceIdentifiers = [
            "Simulator"
        ]
        print("🧪 AdMob test device enabled")
        #endif

        return true
    }
}
#endif

#if os(macOS)
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {

        // 🔥 Firebase
        FirebaseApp.configure()
        print("🔥 Firebase configured (macOS)")

        // 🚫 AdMob not supported natively on macOS
    }
}
#endif
