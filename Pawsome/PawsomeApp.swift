import SwiftUI
import FirebaseStorage

@main
struct PawsomeApp: App {
    @State private var isLoggedIn: Bool = false
    @State private var username: String = ""
    @State private var isLoadingImage: Bool = true
    @StateObject private var profileViewModel = ProfileViewModel()

    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                if profileViewModel.isLoading {
                    ProgressView("Loading Profile...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                        .onAppear {
                            profileViewModel.loadProfileImage(for: username)
                        }
                } else {
                    TabView {
                        HomeView(
                            isLoggedIn: $isLoggedIn,
                            currentUsername: $username,
                            profileImage: $profileViewModel.profileImage,
                            onPostCreated: {
                                profileViewModel.loadProfileImage(for: username)
                            }
                        )
                        .tabItem {
                            Label("Home", systemImage: "house")
                        }

                        ScanView(
                            selectedImage: .constant(nil),
                            username: username,
                            onPostCreated: {
                                profileViewModel.loadProfileImage(for: username)
                            }
                        )
                        .tabItem {
                            Label("Post", systemImage: "plus.app")
                        }

                        // Now Profile View is handled here as a UI, with the ProfileViewModel
                        VStack {
                            if let profileImage = profileViewModel.profileImage {
                                Image(platformImage: profileImage) // Custom view to show platform images
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                    .padding()
                            } else {
                                Text("No profile image available")
                                    .foregroundColor(.gray)
                                    .padding()
                            }

                            Text(username)
                                .font(.title)
                                .padding()

                            // You can add other profile-related UI components here
                        }
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
