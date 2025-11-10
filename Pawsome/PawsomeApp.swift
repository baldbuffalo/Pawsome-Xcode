import SwiftUI
import FirebaseAuth
import GoogleSignIn

@main
struct PawsomeApp: App {
    // MARK: - AppDelegate adaptor
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    #endif

    // MARK: - App State
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            if appState.isLoggedIn {
                MainTabView(appState: appState)
            } else {
                LoginView(
                    isLoggedIn: $appState.isLoggedIn,
                    username: $appState.currentUsername,
                    profileImage: Binding<String?>(
                        get: { appState.profileImageURL.isEmpty ? nil : appState.profileImageURL },
                        set: { appState.profileImageURL = $0 ?? "" }
                    )
                )
                .onAppear { appState.listenAuthState() }
            }
        }
    }
}

// MARK: - App State
final class AppState: ObservableObject {
    @Published var isLoggedIn = false
    @Published var currentUsername = ""
    @Published var profileImageURL = ""

    func listenAuthState() {
        _ = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.isLoggedIn = (user != nil)
                self?.currentUsername = user?.displayName ?? "User\(Int.random(in: 1000...9999))"
                self?.profileImageURL = user?.photoURL?.absoluteString ?? ""
            }
        }
    }
}

// MARK: - Main TabView
struct MainTabView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        TabView {
            HomeView(
                isLoggedIn: $appState.isLoggedIn,
                currentUsername: $appState.currentUsername,
                profileImageURL: Binding<String?>(
                    get: { appState.profileImageURL.isEmpty ? nil : appState.profileImageURL },
                    set: { appState.profileImageURL = $0 ?? "" }
                ),
                onPostCreated: { print("🔥 Post created!") }
            )
            .tabItem { Label("Home", systemImage: "house.fill") }

            ScanView(
                username: appState.currentUsername,
                onPostCreated: { print("📸 Scan post created!") }
            )
            .tabItem { Label("Scan", systemImage: "camera.viewfinder") }

            ProfileView(
                isLoggedIn: $appState.isLoggedIn,
                currentUsername: $appState.currentUsername,
                profileImageURL: Binding<String?>(
                    get: { appState.profileImageURL.isEmpty ? nil : appState.profileImageURL },
                    set: { appState.profileImageURL = $0 ?? "" }
                )
            )
            .tabItem { Label("Profile", systemImage: "person.fill") }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
