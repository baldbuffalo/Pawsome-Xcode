import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore

@main
struct PawsomeApp: App {
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    #elseif os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    #endif

    @State private var isLoggedIn: Bool = false
    @State private var username: String
    @StateObject private var profileViewModel: ProfileViewModel

    init() {
        let savedUsername = UserDefaults.standard.string(forKey: "username") ?? ""
        let usernameState = State(initialValue: savedUsername)
        _username = usernameState
        _profileViewModel = StateObject(wrappedValue: ProfileViewModel(username: usernameState.projectedValue))
    }

    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                if profileViewModel.isLoading {
                    ProgressView("Loading Profile...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                        .onAppear {
                            profileViewModel.loadProfileData()
                        }
                } else {
                    TabView {
                        HomeView(
                            isLoggedIn: $isLoggedIn,
                            currentUsername: $username,
                            profileImage: $profileViewModel.profileImage,
                            onPostCreated: {
                                profileViewModel.loadProfileData()
                            }
                        )
                        .tabItem {
                            Label("Home", systemImage: "house")
                        }

                        ScanView(
                            selectedImage: .constant(nil),
                            username: username,
                            onPostCreated: {
                                profileViewModel.loadProfileData()
                            }
                        )
                        .tabItem {
                            Label("Post", systemImage: "plus.app")
                        }

                        ProfileView(
                            isLoggedIn: $isLoggedIn,
                            currentUsername: $username,
                            profileImage: $profileViewModel.profileImage
                        )
                        .tabItem {
                            Label("Profile", systemImage: "person.crop.circle")
                        }
                    }
                    .environmentObject(profileViewModel)
                }
            } else {
                LoginView(
                    isLoggedIn: $isLoggedIn,
                    username: $username,
                    profileImage: $profileViewModel.profileImage
                )
            }
        }
    }
}
