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

                // 🔒 AUTH GATE (no login flicker)
                if !appState.isAuthChecked {
                    LoadingView()
                } else if appState.isLoggedIn {
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
            .onAppear {
                appState.observeAuthState()
            }
        }
    }

    // MARK: - HOME FLOW
    enum HomeFlow {
        case scan
        case form
    }

    // MARK: - APP STATE
    @MainActor
    final class AppState: ObservableObject {

        @Published var isLoggedIn = false
        @Published var isAuthChecked = false
        @Published var currentUsername = ""
        @Published var profileImageURL: String?
        @Published var selectedImage: PlatformImage? = nil

        private var authListener: AuthStateDidChangeListenerHandle?
        lazy var db: Firestore = Firestore.firestore()

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

            do {
                try Auth.auth().signOut()
            } catch {
                print("❌ Sign out failed:", error)
            }

            isLoggedIn = false
            currentUsername = ""
            profileImageURL = nil
            selectedImage = nil
        }

        func observeAuthState() {
            authListener = Auth.auth().addStateDidChangeListener { _, user in
                if let user {
                    Task {
                        await self.fetchOrCreateUser(
                            uid: user.uid,
                            defaultUsername: user.displayName,
                            defaultImage: user.photoURL?.absoluteString
                        )
                        self.isAuthChecked = true
                    }
                } else {
                    self.isLoggedIn = false
                    self.isAuthChecked = true
                }
            }
        }

        func fetchOrCreateUser(
            uid: String,
            defaultUsername: String?,
            defaultImage: String?
        ) async {

            let userRef = db.collection("users").document(uid)
            let counterRef = db.collection("counter").document("users")

            do {
                let doc = try await userRef.getDocument()

                if doc.exists {
                    let data = doc.data() ?? [:]
                    login(
                        username: data["username"] as? String ?? "User",
                        imageURL: data["profilePic"] as? String
                    )
                    return
                }

                let newUserNumber = try await db.runTransaction { transaction, errorPointer in
                    do {
                        let counterSnap = try transaction.getDocument(counterRef)
                        let last = counterSnap.data()?["lastUserNumber"] as? Int ?? 0
                        let next = last + 1

                        transaction.updateData(
                            ["lastUserNumber": next],
                            forDocument: counterRef
                        )

                        transaction.setData([
                            "userNumber": next,
                            "username": defaultUsername ?? "User\(next)",
                            "profilePic": defaultImage ?? "",
                            "createdAt": Timestamp()
                        ], forDocument: userRef)

                        return next
                    } catch {
                        errorPointer?.pointee = error as NSError
                        return nil
                    }
                }

                login(
                    username: defaultUsername ?? "User\(newUserNumber ?? 0)",
                    imageURL: defaultImage
                )

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
            .onAppear {
                adManager.currentScreen = .home
            }
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

    // MARK: - LOADING VIEW (CENTERED, GLOWED UP)
    struct LoadingView: View {
        @State private var spin = false

        var body: some View {
            ZStack {
                Color.black
                    .opacity(0.05)
                    .ignoresSafeArea()

                Circle()
                    .trim(from: 0.2, to: 1)
                    .stroke(
                        LinearGradient(
                            colors: [.blue, .purple, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(spin ? 360 : 0))
                    .animation(
                        .linear(duration: 1)
                        .repeatForever(autoreverses: false),
                        value: spin
                    )
                    .onAppear {
                        spin = true
                    }
            }
        }
    }
}
