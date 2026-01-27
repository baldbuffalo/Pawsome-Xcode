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
                    MainTabView(appState: appState, activeHomeFlow: $activeHomeFlow)
                        .environmentObject(appState)
                } else {
                    LoginView(appState: appState)
                }

                adManager.overlay
            }
            .environmentObject(adManager)
            .onAppear {
                appState.observeAuthState()
            }
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

        private var authListener: AuthStateDidChangeListenerHandle?  // 👈 store listener

        lazy var db: Firestore = Firestore.firestore()

        // MARK: - LOGIN / LOGOUT
        func login(username: String, imageURL: String?) {
            isLoggedIn = true
            currentUsername = username
            profileImageURL = imageURL
        }

        func logout() {
            if let handle = authListener {
                Auth.auth().removeStateDidChangeListener(handle)
                authListener = nil
            }

            do { try Auth.auth().signOut() } catch { print("❌ Sign out failed:", error) }
            isLoggedIn = false
            currentUsername = ""
            profileImageURL = nil
            selectedImage = nil
        }

        // MARK: - OBSERVE AUTH STATE
        func observeAuthState() {
            authListener = Auth.auth().addStateDidChangeListener { _, user in
                guard let user else {
                    self.isLoggedIn = false
                    return
                }

                Task {
                    await self.fetchOrCreateUser(
                        uid: user.uid,
                        defaultUsername: user.displayName,
                        defaultImage: user.photoURL?.absoluteString
                    )
                }
            }
        }

        // MARK: - FETCH OR CREATE FIRESTORE USER
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

                // New user → atomic counter
                let newUserNumber = try await db.runTransaction { transaction, errorPointer in
                    do {
                        let counterSnap = try transaction.getDocument(counterRef)
                        let lastNumber = counterSnap.data()?["lastUserNumber"] as? Int ?? 0
                        let nextNumber = lastNumber + 1

                        transaction.updateData(["lastUserNumber": nextNumber], forDocument: counterRef)

                        let username = defaultUsername ?? "User\(nextNumber)"
                        let profilePic = defaultImage ?? ""

                        transaction.setData([
                            "userNumber": nextNumber,
                            "username": username,
                            "profilePic": profilePic,
                            "createdAt": Timestamp()
                        ], forDocument: userRef)

                        return nextNumber
                    } catch {
                        errorPointer?.pointee = error as NSError
                        return nil
                    }
                }

                let finalUsername = defaultUsername ?? "User\(newUserNumber ?? 0)"
                let finalProfilePic = defaultImage ?? ""
                await MainActor.run { login(username: finalUsername, imageURL: finalProfilePic) }

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
                .tabItem { Label(tabTitle(for: activeHomeFlow), systemImage: "house") }
                .tag(0)

                ProfileView(appState: appState)
                    .tabItem { Label("Profile", systemImage: "person.crop.circle") }
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
