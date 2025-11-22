import SwiftUI

// --------------------------------------------------
// MARK: - GLOBAL APP STATE
// --------------------------------------------------
@MainActor
class AppState: ObservableObject {
    @Published var isLoggedIn: Bool
    @Published var username: String
    @Published var profileImageURL: String?

    init() {
        self.isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
        self.username = UserDefaults.standard.string(forKey: "username") ?? ""
        let storedImage = UserDefaults.standard.string(forKey: "profileImageURL")
        self.profileImageURL = storedImage?.isEmpty == true ? nil : storedImage
    }

    func logout() {
        isLoggedIn = false
        username = ""
        profileImageURL = nil

        UserDefaults.standard.set(false, forKey: "isLoggedIn")
        UserDefaults.standard.removeObject(forKey: "username")
        UserDefaults.standard.removeObject(forKey: "profileImageURL")
    }
}

// --------------------------------------------------
// MARK: - APP ENTRY
// --------------------------------------------------
@main
struct PawsomeApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            if appState.isLoggedIn == false {
                LoginView(
                    isLoggedIn: Binding(
                        get: { appState.isLoggedIn },
                        set: { appState.isLoggedIn = $0 }
                    ),
                    username: Binding(
                        get: { appState.username },
                        set: { appState.username = $0 }
                    ),
                    profileImage: Binding(
                        get: { appState.profileImageURL },
                        set: { appState.profileImageURL = $0 }
                    )
                )
            } else {
                MainTabView(appState: appState)
            }
        }
    }
}

// --------------------------------------------------
// MARK: - MAIN TAB VIEW
// --------------------------------------------------
struct MainTabView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        TabView {

            HomeView(
                isLoggedIn: Binding(
                    get: { appState.isLoggedIn },
                    set: { appState.isLoggedIn = $0 }
                ),
                currentUsername: Binding(
                    get: { appState.username },
                    set: { appState.username = $0 }
                ),
                profileImageURL: Binding(
                    get: { appState.profileImageURL },
                    set: { appState.profileImageURL = $0 }
                ),
                onPostCreated: {
                    // empty handler for now
                    print("Post created!")
                }
            )
            .tabItem {
                Label("Home", systemImage: "house")
            }

            ProfileView(
                isLoggedIn: Binding(
                    get: { appState.isLoggedIn },
                    set: { appState.isLoggedIn = $0 }
                ),
                currentUsername: Binding(
                    get: { appState.username },
                    set: { appState.username = $0 }
                ),
                profileImageURL: Binding(
                    get: { appState.profileImageURL },
                    set: { appState.profileImageURL = $0 }
                )
            )
            .tabItem {
                Label("Profile", systemImage: "person")
            }
        }
    }
}
