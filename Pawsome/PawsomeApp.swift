import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

@main
struct PawsomeApp: App {

    // 🔥 AppDelegate hookup (Firebase config lives there)
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    #elseif os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    #endif

    @StateObject private var appState = AppState()
    @StateObject private var adManager = AdManager.shared
    @State private var activeHomeFlow: HomeFlow? = nil

    var body: some Scene {
        WindowGroup {
            ZStack(alignment: .bottom) {
                if appState.isLoggedIn {
                    MainTabView(
                        appState: appState,
                        activeHomeFlow: $activeHomeFlow
                    )
                } else {
                    LoginView(appState: appState)
                }

                adManager.overlay
            }
            .environmentObject(adManager)
        }
    }

    // MARK: - Home Flow
    enum HomeFlow {
        case scan
        case form
    }

    // MARK: - AppState (🔥 FIREBASE-SAFE)
    @MainActor
    final class AppState: ObservableObject {

        @Published var isLoggedIn = false
        @Published var currentUsername = ""
        @Published var profileImageURL: String?

        // 🔥 FIX: Firestore MUST be lazy
        lazy var db: Firestore = {
            Firestore.firestore()
        }()

        init() {
            loadFromDefaults()
        }

        func loadFromDefaults() {
            isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
            currentUsername = UserDefaults.standard.string(forKey: "username") ?? ""
            profileImageURL = UserDefaults.standard.string(forKey: "profileImageURL")
        }

        func login(username: String, imageURL: String?) {
            isLoggedIn = true
            currentUsername = username
            profileImageURL = imageURL

            UserDefaults.standard.set(true, forKey: "isLoggedIn")
            UserDefaults.standard.set(username, forKey: "username")
            UserDefaults.standard.set(imageURL, forKey: "profileImageURL")
        }

        func saveUsername(_ username: String, completion: (() -> Void)? = nil) {
            currentUsername = username
            UserDefaults.standard.set(username, forKey: "username")

            guard let uid = Auth.auth().currentUser?.uid else {
                completion?()
                return
            }

            db.collection("users")
                .document(uid)
                .setData(["username": username], merge: true) { _ in
                    completion?()
                }
        }

        func saveProfileImageURL(_ url: String, completion: (() -> Void)? = nil) {
            profileImageURL = url
            UserDefaults.standard.set(url, forKey: "profileImageURL")

            guard let uid = Auth.auth().currentUser?.uid else {
                completion?()
                return
            }

            db.collection("users")
                .document(uid)
                .setData(["profileImageURL": url], merge: true) { _ in
                    completion?()
                }
        }

        // 🔥 REAL LOGOUT
        func logout() {
            do {
                try Auth.auth().signOut()
            } catch {
                print("❌ Sign out failed:", error)
            }

            isLoggedIn = false
            currentUsername = ""
            profileImageURL = nil

            UserDefaults.standard.removeObject(forKey: "isLoggedIn")
            UserDefaults.standard.removeObject(forKey: "username")
            UserDefaults.standard.removeObject(forKey: "profileImageURL")
        }
    }

    // MARK: - MainTabView
    struct MainTabView: View {
        @ObservedObject var appState: AppState
        @EnvironmentObject var adManager: AdManager

        @Binding var activeHomeFlow: HomeFlow?
        @State private var selectedTab = 0

        var body: some View {
            TabView(selection: $selectedTab) {

                HomeView(
                    isLoggedIn: $appState.isLoggedIn,
                    currentUsername: $appState.currentUsername,
                    profileImageURL: $appState.profileImageURL,
                    activeFlow: $activeHomeFlow
                )
                .tabItem {
                    Label(
                        activeHomeFlow == .scan ? "Scan" :
                        activeHomeFlow == .form ? "Post" : "Home",
                        systemImage: "house"
                    )
                }
                .tag(0)

                ProfileView(appState: appState)
                    .tabItem {
                        Label("Profile", systemImage: "person.crop.circle")
                    }
                    .tag(1)
            }
            .onAppear {
                adManager.currentScreen = .home
            }
            .onChange(of: selectedTab) { _, newValue in
                activeHomeFlow = nil
                adManager.currentScreen = (newValue == 0) ? .home : .profile
            }
        }
    }
}
