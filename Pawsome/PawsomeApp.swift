import SwiftUI
import FirebaseAuth
import FirebaseCore

@main
struct PawsomeApp: App {
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    #elseif os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    #endif

    // MARK: - App State
    @StateObject private var appState = AppState()

    init() {
        print("🔥 PawsomeApp init running")
    }

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
                .onAppear {
                    // Delay listener until Firebase is configured
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        appState.listenAuthState()
                    }
                }
            }
        }
    }

    // MARK: - Embedded AppState
    final class AppState: ObservableObject {
        @Published var isLoggedIn = false
        @Published var currentUsername = ""
        @Published var profileImageURL = ""

        func listenAuthState() {
            guard FirebaseApp.app() != nil else {
                print("⚠️ Firebase not configured yet, delaying auth listener")
                return
            }

            print("👀 Listening for auth state...")
            _ = Auth.auth().addStateDidChangeListener { [weak self] _, user in
                DispatchQueue.main.async {
                    self?.isLoggedIn = (user != nil)
                    self?.currentUsername = user?.displayName ?? "User\(Int.random(in: 1000...9999))"
                    self?.profileImageURL = user?.photoURL?.absoluteString ?? ""
                }
            }
        }
    }
}

// MARK: - Placeholder MainTabView
struct MainTabView: View {
    @ObservedObject var appState: PawsomeApp.AppState

    var body: some View {
        TabView {
            Text("Home View")
                .tabItem { Label("Home", systemImage: "house.fill") }

            Text("Scan View")
                .tabItem { Label("Scan", systemImage: "camera.viewfinder") }

            Text("Profile View")
                .tabItem { Label("Profile", systemImage: "person.fill") }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
