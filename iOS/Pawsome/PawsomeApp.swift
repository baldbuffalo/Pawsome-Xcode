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

    init() { FirebaseApp.configure() }

    @StateObject private var appState = AppState()
    @StateObject private var adManager = AdManager.shared
    @State private var activeHomeFlow: HomeFlow? = nil

    var body: some Scene {
        WindowGroup {
            ZStack(alignment: .bottom) {
                if !appState.isAuthChecked {
                    LoadingView()
                } else if appState.isLoggedIn {
                    MainTabView(appState: appState, activeHomeFlow: $activeHomeFlow).environmentObject(appState)
                } else {
                    LoginView(appState: appState)
                }
                adManager.overlay
            }
            .environmentObject(adManager)
            .onAppear { appState.observeAuthState() }
        }
    }

    enum HomeFlow { case scan, form }

    @MainActor
    final class AppState: ObservableObject {
        @Published var isLoggedIn = false
        @Published var isAuthChecked = false
        @Published var isAdmin = false
        @Published var currentUsername = ""
        @Published var profileImageURL: String?
        @Published var selectedImage: PlatformImage? = nil

        private var authListener: AuthStateDidChangeListenerHandle?
        lazy var db: Firestore = Firestore.firestore()

        func login(username: String, imageURL: String?) { isLoggedIn = true; currentUsername = username; profileImageURL = imageURL }

        func logout() {
            if let handle = authListener { Auth.auth().removeStateDidChangeListener(handle); authListener = nil }
            do { try Auth.auth().signOut() } catch { print("❌ Sign out failed:", error) }
            isLoggedIn = false; isAdmin = false; currentUsername = ""; profileImageURL = nil; selectedImage = nil
        }

        func observeAuthState() {
            authListener = Auth.auth().addStateDidChangeListener { _, user in
                if let user {
                    Task {
                        await self.refreshAdminStatus(for: user)
                        await self.fetchOrCreateUser(uid: user.uid, defaultUsername: user.displayName, defaultImage: user.photoURL?.absoluteString)
                        self.isAuthChecked = true
                    }
                } else {
                    self.isLoggedIn = false; self.isAdmin = false; self.isAuthChecked = true
                }
            }
        }

        private func refreshAdminStatus(for user: User) async {
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                user.getIDTokenResult { result, error in
                    let isAdmin = (result?.claims["admin"] as? NSNumber)?.boolValue ?? false
                    if let error { print("❌ Admin claim check failed:", error.localizedDescription) }
                    Task { @MainActor in self.isAdmin = isAdmin; continuation.resume() }
                }
            }
        }

        func fetchOrCreateUser(uid: String, defaultUsername: String?, defaultImage: String?) async {
            let userRef = db.collection("users").document(uid)
            let counterRef = db.collection("counter").document("users")
            do {
                let doc = try await userRef.getDocument()
                if doc.exists {
                    let data = doc.data() ?? [:]
                    login(username: data["username"] as? String ?? data["Username"] as? String ?? "User", imageURL: data["profilePic"] as? String ?? data["ProfilePic"] as? String)
                    return
                }
                let newUserNumber = try await db.runTransaction { transaction, errorPointer in
                    do {
                        let counterSnap = try transaction.getDocument(counterRef)
                        let next = (counterSnap.data()?["lastUserNumber"] as? Int ?? 0) + 1
                        transaction.updateData(["lastUserNumber": next], forDocument: counterRef)
                        transaction.setData(["userNumber": next, "username": defaultUsername ?? "User\(next)", "profilePic": defaultImage ?? "", "createdAt": Timestamp()], forDocument: userRef)
                        return next
                    } catch { errorPointer?.pointee = error as NSError; return nil }
                }
                login(username: defaultUsername ?? "User\(newUserNumber ?? 0)", imageURL: defaultImage)
            } catch { print("❌ User fetch/create error:", error.localizedDescription) }
        }
    }

    struct MainTabView: View {
        @ObservedObject var appState: AppState
        @EnvironmentObject var adManager: AdManager
        @Binding var activeHomeFlow: HomeFlow?
        @State private var selectedTab = 0
        var body: some View {
            TabView(selection: $selectedTab) {
                ZStack {
                    switch activeHomeFlow {
                    case .form: FormView(activeHomeFlow: $activeHomeFlow, onPostCreated: { appState.selectedImage = nil; activeHomeFlow = nil }).environmentObject(appState)
                    case .scan, .none: HomeView(isLoggedIn: $appState.isLoggedIn, currentUsername: $appState.currentUsername, profileImageURL: $appState.profileImageURL, activeFlow: $activeHomeFlow)
                    }
                }
                .overlay { if activeHomeFlow == .scan { ScanView(activeHomeFlow: $activeHomeFlow, username: appState.currentUsername).environmentObject(appState) } }
                .tabItem { Label(tabTitle(for: activeHomeFlow), systemImage: "house") }.tag(0)
                ProfileView(appState: appState).tabItem { Label("Profile", systemImage: "person.crop.circle") }.tag(1)
            }
            .onAppear { adManager.updateCurrentScreen(selectedTab: selectedTab, activeHomeFlow: activeHomeFlow) }
            .onChange(of: selectedTab) { _, newValue in activeHomeFlow = nil; adManager.updateCurrentScreen(selectedTab: newValue, activeHomeFlow: activeHomeFlow) }
            .onChange(of: activeHomeFlow) { _, newValue in adManager.updateCurrentScreen(selectedTab: selectedTab, activeHomeFlow: newValue) }
        }
        private func tabTitle(for flow: HomeFlow?) -> String { switch flow { case .scan: return "Scan"; case .form: return "Post"; case .none: return "Home" } }
    }

    struct LoadingView: View {
        @State private var spin = false
        var body: some View { ZStack { Color.black.opacity(0.05).ignoresSafeArea(); Circle().trim(from: 0.2, to: 1).stroke(Color(red: 0.49, green: 0.23, blue: 0.93), style: StrokeStyle(lineWidth: 6, lineCap: .round)).frame(width: 60, height: 60).rotationEffect(.degrees(spin ? 360 : 0)).animation(.linear(duration: 1).repeatForever(autoreverses: false), value: spin).onAppear { spin = true } } }
    }
}
