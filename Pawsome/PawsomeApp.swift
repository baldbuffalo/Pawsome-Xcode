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
    @State private var activeHomeFlow: HomeFlow? = nil

    var body: some Scene {
        WindowGroup {
            ZStack(alignment: .bottom) {
                if appState.isLoggedIn {
                    MainTabView(
                        appState: appState,
                        activeHomeFlow: $activeHomeFlow
                    )
                    .environmentObject(appState)
                } else {
                    LoginView(appState: appState)
                }

                adManager.overlay
            }
            .environmentObject(adManager)
        }
    }

    // MARK: - HOME FLOW
    enum HomeFlow { case scan, form }

    // MARK: - APP STATE
    @MainActor
    final class AppState: ObservableObject {
        @Published var isLoggedIn = false
        @Published var currentUsername = ""
        @Published var profileImageURL: String?
        @Published var selectedImage: PlatformImage? = nil

        lazy var db: Firestore = Firestore.firestore()

        func login(username: String, imageURL: String?) {
            isLoggedIn = true
            currentUsername = username
            profileImageURL = imageURL
            UserDefaults.standard.set(true, forKey: "isLoggedIn")
            UserDefaults.standard.set(username, forKey: "username")
            UserDefaults.standard.set(imageURL, forKey: "profileImageURL")
        }

        func logout() {
            do { try Auth.auth().signOut() } catch { print("❌ Sign out failed:", error) }
            isLoggedIn = false
            currentUsername = ""
            profileImageURL = nil
            selectedImage = nil
            UserDefaults.standard.removeObject(forKey: "isLoggedIn")
            UserDefaults.standard.removeObject(forKey: "username")
            UserDefaults.standard.removeObject(forKey: "profileImageURL")
        }

        // MARK: - FIRESTORE USER CREATION WITH COUNTER
        func fetchOrCreateUser(uid: String, defaultUsername: String?, defaultImage: String?) async {
            let userRef = db.collection("users").document(uid)
            let counterRef = db.collection("counter").document("users")

            do {
                let doc = try await userRef.getDocument()
                if doc.exists {
                    let data = doc.data() ?? [:]
                    await MainActor.run {
                        login(
                            username: data["username"] as? String ?? "User",
                            imageURL: data["profilePic"] as? String
                        )
                    }
                    return
                }

                // 🔥 New user → atomic counter for userNumber
                let newUserNumber = try await db.runTransaction { transaction, _ in
                    let counterDoc = try transaction.getDocument(counterRef)
                    let lastNumber = counterDoc.data()?["lastUserNumber"] as? Int ?? 0
                    let nextNumber = lastNumber + 1
                    transaction.updateData(["lastUserNumber": nextNumber], forDocument: counterRef)
                    return nextNumber
                }

                let username = defaultUsername ?? "User\(newUserNumber)"
                let profilePic = defaultImage ?? ""

                try await userRef.setData([
                    "userNumber": newUserNumber,
                    "username": username,
                    "profilePic": profilePic,
                    "createdAt": Timestamp()
                ])

                await MainActor.run { login(username: username, imageURL: profilePic) }

            } catch {
                print("❌ User fetch/create error:", error.localizedDescription)
            }
        }
    }

    // MARK: - MAIN TAB VIEW
    struct MainTabView: View {

        @ObservedObject var appState: AppState
        @EnvironmentObject var adManager: AdManager
        @Binding var activeHomeFlow: HomeFlow?
        @State private var selectedTab = 0

        var body: some View {
            TabView(selection: $selectedTab) {

                ZStack {
                    switch activeHomeFlow {

                    case .scan:
                        ScanView(
                            activeHomeFlow: $activeHomeFlow,
                            username: appState.currentUsername
                        )
                        .environmentObject(appState)

                    case .form:
                        FormView(
                            activeHomeFlow: $activeHomeFlow,
                            onPostCreated: {
                                appState.selectedImage = nil
                                activeHomeFlow = nil
                            }
                        )
                        .environmentObject(appState)

                    case .none:
                        HomeView(
                            isLoggedIn: $appState.isLoggedIn,
                            currentUsername: $appState.currentUsername,
                            profileImageURL: $appState.profileImageURL,
                            activeFlow: $activeHomeFlow
                        )
                    }
                }
                .tabItem {
                    Label(tabTitle(for: activeHomeFlow), systemImage: "house")
                }
                .tag(0)

                ProfileView(appState: appState)
                    .tabItem {
                        Label("Profile", systemImage: "person.crop.circle")
                    }
                    .tag(1)
            }
            .onAppear { adManager.currentScreen = .home }
            .onChange(of: selectedTab) { _, newValue in
                activeHomeFlow = nil
                adManager.currentScreen = (newValue == 0) ? .home : .profile
            }
        }

        private func tabTitle(for flow: HomeFlow?) -> String {
            switch flow {
            case .scan: return "Scan"
            case .form: return "Post"
            case .none: return "Home"
            }
        }
    }
}
