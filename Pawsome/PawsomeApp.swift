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
    @StateObject private var adManager = AdManager.shared

    // GLOBAL FLOW STATE
    @State private var activeHomeFlow: HomeFlow? = nil

    init() {
        print("🔥 PawsomeApp launched!")
    }

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

                // GLOBAL STICKY BOTTOM AD
                adManager.overlay
            }
            .environmentObject(adManager)
        }
    }

    // MARK: - Home Flow Enum
    enum HomeFlow {
        case scan
        case form
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
            currentUsername = UserDefaults.standard.string(forKey: "username")
                ?? "User\(Int.random(in: 1000...9999))"
            profileImageURL = UserDefaults.standard.string(forKey: "profileImageURL")
        }

        func setLoggedIn(_ loggedIn: Bool) {
            isLoggedIn = loggedIn
            UserDefaults.standard.set(loggedIn, forKey: "isLoggedIn")
        }

        // 🔑 Save username
        func saveUsername(_ username: String, completion: (() -> Void)? = nil) {
            currentUsername = username
            UserDefaults.standard.set(username, forKey: "username")
            guard let uid = Auth.auth().currentUser?.uid else { completion?(); return }
            db.collection("users").document(uid)
                .setData(["username": username], merge: true) { _ in completion?() }
        }

        // 🔑 Save profile image URL
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
                        // 🔥 Dynamic tab label
                        (activeHomeFlow == .scan ? "Scan" :
                         activeHomeFlow == .form ? "Post" : "Home"),
                        systemImage: "house"
                    )
                }
                .tag(0)

                ProfileView(appState: appState)
                    .tabItem { Label("Profile", systemImage: "person.crop.circle") }
                    .tag(1)
            }
            .onAppear {
                adManager.currentScreen = .home
            }
            .onChange(of: selectedTab) { _, newValue in
                // 🧼 HARD RESET HOME FLOW WHEN TAB CHANGES
                activeHomeFlow = nil

                adManager.currentScreen = (newValue == 0) ? .home : .profile
            }
        }
    }
}
