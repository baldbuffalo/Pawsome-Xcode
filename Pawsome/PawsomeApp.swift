import SwiftUI

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
                        appState.checkLoginState()
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

        func checkLoginState() {
            // Local simulation for login
            isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
            currentUsername = UserDefaults.standard.string(forKey: "username") ?? "User\(Int.random(in: 1000...9999))"
            profileImageURL = UserDefaults.standard.string(forKey: "profileImageURL") ?? ""
            print("👀 Login state checked locally")
        }

        func logIn(username: String, profileImageURL: String? = nil) {
            self.currentUsername = username
            self.profileImageURL = profileImageURL ?? ""
            self.isLoggedIn = true
            UserDefaults.standard.set(true, forKey: "isLoggedIn")
            UserDefaults.standard.set(username, forKey: "username")
            UserDefaults.standard.set(profileImageURL ?? "", forKey: "profileImageURL")
        }

        func logOut() {
            self.currentUsername = ""
            self.profileImageURL = ""
            self.isLoggedIn = false
            UserDefaults.standard.removeObject(forKey: "username")
            UserDefaults.standard.removeObject(forKey: "profileImageURL")
            UserDefaults.standard.set(false, forKey: "isLoggedIn")
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

    // MARK: - LoginView (simple local version)
    struct LoginView: View {
        @Binding var isLoggedIn: Bool
        @Binding var username: String
        @Binding var profileImage: String?

        @State private var inputUsername = ""

        var body: some View {
            VStack(spacing: 20) {
                Text("Login")
                    .font(.largeTitle)
                    .padding()

                TextField("Enter username", text: $inputUsername)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button("Log In") {
                    username = inputUsername.isEmpty ? "User\(Int.random(in: 1000...9999))" : inputUsername
                    profileImage = nil
                    isLoggedIn = true
                    UserDefaults.standard.set(true, forKey: "isLoggedIn")
                    UserDefaults.standard.set(username, forKey: "username")
                }
                .padding()
                .foregroundColor(.white)
                .background(Color.blue)
                .cornerRadius(8)

                Spacer()
            }
            .padding()
        }
    }
}
