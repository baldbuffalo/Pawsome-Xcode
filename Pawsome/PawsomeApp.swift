import SwiftUI
import Firebase
import FirebaseAuth

@main
struct PawsomeApp: App {
    // MARK: - AppDelegate adaptor
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    #elseif os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    #endif

    // MARK: - App state
    @State private var isLoggedIn = false
    @State private var currentUsername: String = ""    // non-optional
    @State private var profileImageURL: String = ""    // non-optional internally

    var body: some Scene {
        WindowGroup {
            contentView
                .onAppear {
                    setupFirebaseIfNeeded()
                    setupAuthStateObserver()
                }
        }
    }

    // MARK: - Conditional content
    @ViewBuilder
    private var contentView: some View {
        if isLoggedIn {
            mainTabView
        } else {
            // LoginView expects `username: Binding<String>` and `profileImage: Binding<String?>`
            LoginView(
                isLoggedIn: $isLoggedIn,
                username: $currentUsername,
                profileImage: Binding<String?>(
                    get: { profileImageURL.isEmpty ? nil : profileImageURL },
                    set: { profileImageURL = $0 ?? "" }
                )
            )
        }
    }

    // MARK: - Main TabView
    private var mainTabView: some View {
        TabView {
            HomeView(
                isLoggedIn: $isLoggedIn,
                currentUsername: $currentUsername,   // non-optional
                profileImageURL: Binding<String?>(
                    get: { profileImageURL.isEmpty ? nil : profileImageURL },
                    set: { profileImageURL = $0 ?? "" }
                ),
                onPostCreated: { print("🔥 Post created!") }
            )
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }

            ProfileView(
                isLoggedIn: $isLoggedIn,
                currentUsername: $currentUsername,   // non-optional
                profileImageURL: Binding<String?>(
                    get: { profileImageURL.isEmpty ? nil : profileImageURL },
                    set: { profileImageURL = $0 ?? "" }
                )
            )
            .tabItem {
                Label("Profile", systemImage: "person.fill")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Firebase setup
    private func setupFirebaseIfNeeded() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            print("✅ Firebase configured")
        }
    }

    // MARK: - Firebase Auth listener
    private func setupAuthStateObserver() {
        _ = Auth.auth().addStateDidChangeListener { _, user in
            DispatchQueue.main.async {
                self.isLoggedIn = (user != nil)
                self.currentUsername = user?.displayName ?? "User\(Int.random(in: 1000...9999))"
                self.profileImageURL = user?.photoURL?.absoluteString ?? ""
            }
        }
    }
}
