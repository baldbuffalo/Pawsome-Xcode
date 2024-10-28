#if canImport(UIKit)
import UIKit
import Firebase
import GoogleSignIn
import AVFoundation

class AppDelegate: NSObject, UIApplicationDelegate {
    var window: UIWindow?
<<<<<<< HEAD
    var photoOutput: AVCapturePhotoOutput? // Add this line to declare photoOutput
=======
    var photoOutput: AVCapturePhotoOutput? // Declare photoOutput
>>>>>>> 5eef0f8bd39986f9f45e071df446cc125709c1b6

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure() // Initialize Firebase
        return true
    }

    // Handle URL opening for Google Sign-In
    func application(_ app: UIApplication, open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}
#endif
