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

    init() { FirebaseApp.configure() }

    var body: some Scene {
        WindowGroup {
            Group {
                if !appState.isAuthChecked {
                    LoadingView()
                } else if appState.isLoggedIn {
                    MainTabView(appState: appState)
                } else {
                    LoginView(appState: appState)
                }
            }
            .environmentObject(appState)
            .environmentObject(adManager)
            .onAppear { appState.observeAuthState() }
        }
    }

    @MainActor
    final class AppState: ObservableObject {
        @Published var isLoggedIn = false
        @Published var isAuthChecked = false
        @Published var isAdmin = false
        @Published var currentUsername = ""
        @Published var currentUserID: Int?
        @Published var profileImageURL: String?
        @Published var selectedImage: PlatformImage?
        @Published var startupError: String?

        private var authListener: AuthStateDidChangeListenerHandle?
        lazy var db: Firestore = Firestore.firestore()

        func login(username: String, imageURL: String?, userID: Int? = nil) {
            isLoggedIn = true
            currentUsername = username
            profileImageURL = imageURL
            if let userID { currentUserID = userID }
        }

        func logout() {
            if let handle = authListener { Auth.auth().removeStateDidChangeListener(handle); authListener = nil }
            do { try Auth.auth().signOut() } catch { print("❌ Sign out failed:", error) }
            isLoggedIn = false
            isAdmin = false
            currentUsername = ""
            currentUserID = nil
            profileImageURL = nil
            selectedImage = nil
            startupError = nil
            isAuthChecked = true
        }

        func observeAuthState() {
            guard authListener == nil else { return }
            authListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
                guard let self else { return }
                if let user {
                    Task { @MainActor in
                        do {
                            try await self.verifyFirebaseAndLoadUser(user)
                            self.isAuthChecked = true
                        } catch {
                            self.isLoggedIn = false
                            self.currentUserID = nil
                            self.startupError = error.localizedDescription
                            self.isAuthChecked = true
                        }
                    }
                } else {
                    self.isLoggedIn = false
                    self.isAdmin = false
                    self.currentUsername = ""
                    self.currentUserID = nil
                    self.profileImageURL = nil
                    self.startupError = nil
                    self.isAuthChecked = true
                }
            }
        }

        private func verifyFirebaseAndLoadUser(_ user: User) async throws {
            let token = try await user.getIDTokenResult(forcingRefresh: false)
            isAdmin = (token.claims["admin"] as? Bool) ?? false
            try await fetchOrCreateUser(uid: user.uid, defaultUsername: user.displayName, defaultImage: user.photoURL?.absoluteString)
            _ = try await db.collection("posts").order(by: "PostedAt", descending: true).limit(to: 1).getDocuments()
        }

        func fetchOrCreateUser(uid: String, defaultUsername: String?, defaultImage: String?) async throws {
            let userRef = db.collection("users").document(uid)
            let counterRef = db.collection("counter").document("users")
            let doc = try await userRef.getDocument()
            if doc.exists {
                let data = doc.data() ?? [:]
                login(
                    username: data["Username"] as? String ?? "User",
                    imageURL: data["ProfilePic"] as? String ?? "",
                    userID: data["UserID"] as? Int
                )
                return
            }

            let newUserID = try await db.runTransaction { transaction, errorPointer -> Int? in
                do {
                    let existing = try transaction.getDocument(userRef)
                    if existing.exists { return existing.data()?["UserID"] as? Int ?? 0 }
                    let counterSnap = try transaction.getDocument(counterRef)
                    let next = (counterSnap.data()?["lastUserID"] as? Int ?? 0) + 1
                    transaction.setData(["lastUserID": next], forDocument: counterRef, merge: true)
                    transaction.setData([
                        "Username": defaultUsername ?? "User\(next)",
                        "ProfilePic": defaultImage ?? "",
                        "UserID": next,
                        "LoginMethod": loginMethod(for: userIDProvider(uid)),
                        "JoinedOn": FieldValue.serverTimestamp()
                    ], forDocument: userRef, merge: false)
                    return next
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }
            }
            guard let newUserID else { throw NSError(domain: "Pawsome", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not create user profile."]) }
            login(username: defaultUsername ?? "User\(newUserID)", imageURL: defaultImage, userID: newUserID)
        }

        private func userIDProvider(_ uid: String) -> User { Auth.auth().currentUser ?? User() }

        private func loginMethod(for user: User) -> String {
            let provider = user.providerData.first(where: { $0.providerID != "firebase" })?.providerID
            switch provider {
            case "google.com": return "Google"
            case "twitter.com": return "Twitter"
            case "apple.com": return "Apple"
            case "password": return "Email/Password"
            default: return provider?.split(separator: ".").first.map(String.init).map { $0.capitalized } ?? "Unknown"
            }
        }
    }

    struct MainTabView: View {
        @ObservedObject var appState: AppState
        @State private var selectedTab = 0
        @State private var creating = false
        @State private var showAdmin = false

        var body: some View {
            TabView(selection: $selectedTab) {
                Group {
                    if creating {
                        FormView(activeHomeFlow: .constant(.form), onPostCreated: { creating = false })
                    } else {
                        HomeView(
                            isLoggedIn: $appState.isLoggedIn,
                            currentUsername: $appState.currentUsername,
                            profileImageURL: $appState.profileImageURL,
                            activeFlow: .constant(nil)
                        )
                    }
                }
                .environmentObject(appState)
                .tabItem { Label(creating ? "Post" : "Home", systemImage: creating ? "plus" : "house.fill") }
                .tag(0)

                ProfileView(appState: appState)
                    .environmentObject(appState)
                    .tabItem { Label("Profile", systemImage: "person.fill") }
                    .tag(1)

                if appState.isAdmin {
                    AdminView(appState: appState)
                        .tabItem { Label("Admin", systemImage: "person.badge.key.fill") }
                        .tag(2)
                }
            }
            .onChange(of: selectedTab) { _, _ in creating = false }
            .onChange(of: creating) { _, value in if value { selectedTab = 0 } }
            .safeAreaInset(edge: .top) {
                if creating {
                    Color.clear.frame(height: 0)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    struct LoadingView: View {
        var body: some View {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                ProgressView().controlSize(.large)
            }
        }
    }
}
