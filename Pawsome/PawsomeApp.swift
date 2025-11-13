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
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        appState.listenAuthState()
                    }
                }
            }
        }
    }

    // MARK: - AppState
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

    // MARK: - MainTabView
    struct MainTabView: View {
        @ObservedObject var appState: AppState

        var body: some View {
            TabView {
                HomeView(username: appState.currentUsername)
                    .tabItem { Label("Home", systemImage: "house") }

                ProfileView(username: appState.currentUsername, profileImage: appState.profileImageURL)
                    .tabItem { Label("Profile", systemImage: "person.crop.circle") }
            }
        }
    }

    // MARK: - HomeView
    struct HomeView: View {
        var username: String

        var body: some View {
            VStack {
                Text("Welcome, \(username)!")
                    .font(.largeTitle)
                    .padding()
                Spacer()
            }
        }
    }

    // MARK: - ProfileView
    struct ProfileView: View {
        var username: String
        var profileImage: String

        var body: some View {
            VStack {
                if let url = URL(string: profileImage), !profileImage.isEmpty {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFit()
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(width: 150, height: 150)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 150, height: 150)
                        .foregroundColor(.gray)
                }

                Text(username)
                    .font(.title)
                    .padding(.top, 20)

                Spacer()
            }
            .padding()
        }
    }
}
