import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

@main
struct PawsomeApp: App {
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    #elseif os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    #endif

    @StateObject private var appState = AppState()
    @StateObject private var adManager = AdManager.shared   // 🔥 AdManager singleton

    init() {
        print("🔥 PawsomeApp launched!")
    }

    var body: some Scene {
        WindowGroup {
            ZStack(alignment: .bottom) {
                if appState.isLoggedIn {
                    MainTabView(appState: appState)
                } else {
                    LoginView(appState: appState)
                }

                // 🔥 GLOBAL STICKY BOTTOM AD
                adManager.overlay
            }
            .environmentObject(adManager) // 🔥 REQUIRED
        }
    }

    // MARK: - AppState
    final class AppState: ObservableObject {
        @Published var isLoggedIn: Bool = false
        @Published var currentUsername: String = ""
        @Published var profileImageURL: String? = nil

        lazy var db: Firestore = Firestore.firestore()

        init() { loadFromDefaults() }

        func loadFromDefaults() {
            isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
            currentUsername = UserDefaults.standard.string(forKey: "username") ?? "User\(Int.random(in: 1000...9999))"
            profileImageURL = UserDefaults.standard.string(forKey: "profileImageURL")
        }

        func setLoggedIn(_ loggedIn: Bool) {
            isLoggedIn = loggedIn
            UserDefaults.standard.set(loggedIn, forKey: "isLoggedIn")
        }

        func saveUsername(_ username: String, completion: (() -> Void)? = nil) {
            currentUsername = username
            UserDefaults.standard.set(username, forKey: "username")
            guard let uid = Auth.auth().currentUser?.uid else { completion?(); return }
            db.collection("users").document(uid)
                .setData(["username": username], merge: true) { _ in completion?() }
        }

        func saveProfileImageURL(_ url: String, completion: (() -> Void)? = nil) {
            profileImageURL = url
            UserDefaults.standard.set(url, forKey: "profileImageURL")
            guard let uid = Auth.auth().currentUser?.uid else { completion?(); return }
            db.collection("users").document(uid)
                .setData(["profileImageURL": url], merge: true) { _ in completion?() }
        }

        func logout() {
            setLoggedIn(false)
            currentUsername = ""
            profileImageURL = nil
            try? Auth.auth().signOut()
            UserDefaults.standard.removeObject(forKey: "isLoggedIn")
            UserDefaults.standard.removeObject(forKey: "username")
            UserDefaults.standard.removeObject(forKey: "profileImageURL")
        }
    }

    // MARK: - MainTabView
    struct MainTabView: View {
        @ObservedObject var appState: AppState
        @EnvironmentObject var adManager: AdManager   // 🔥 link to AdManager
        @State private var selectedTab = 0             // 🔥 tracks tab selection

        var body: some View {
            TabView(selection: $selectedTab) {
                HomeTab()
                    .tabItem { Label("Home", systemImage: "house") }
                    .tag(0)

                ScanTab()
                    .tabItem { Label("Scan", systemImage: "qrcode.viewfinder") }
                    .tag(1)

                ProfileTab()
                    .tabItem { Label("Profile", systemImage: "person.crop.circle") }
                    .tag(2)
            }
            .onAppear {
                adManager.currentScreen = .home
                print("🟢 Current screen: home")
            }
            .onChange(of: selectedTab) { newValue in
                switch newValue {
                case 0:
                    adManager.currentScreen = .home
                    print("🟢 Current screen: home")
                case 1:
                    adManager.currentScreen = .scan
                    print("🟢 Current screen: scan")
                case 2:
                    adManager.currentScreen = .profile
                    print("🟢 Current screen: profile")
                default:
                    adManager.currentScreen = .other
                    print("🟢 Current screen: other")
                }
            }
        }

        @ViewBuilder private func HomeTab() -> some View {
            HomeView(
                isLoggedIn: $appState.isLoggedIn,
                currentUsername: $appState.currentUsername,
                profileImageURL: $appState.profileImageURL,
                onPostCreated: {}
            )
        }

        @ViewBuilder private func ScanTab() -> some View {
            ScanView(
                username: appState.currentUsername,
                onPostCreated: {}
            )
        }

        @ViewBuilder private func ProfileTab() -> some View {
            ProfileView(appState: appState)
        }
    }
}
