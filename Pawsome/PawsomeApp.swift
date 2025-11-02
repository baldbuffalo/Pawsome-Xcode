import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

@main
struct PawsomeApp: App {
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    #elseif os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    #endif

    @State private var isLoggedIn: Bool = false
    @State private var username: String = "Guest"
    @State private var profileImage: PlatformImage? = nil

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if isLoggedIn {
                    NavigationStack {
                        TabView {
                            HomeView(
                                isLoggedIn: $isLoggedIn,
                                currentUsername: $username,
                                profileImage: $profileImage,
                                onPostCreated: {
                                    print("New post created!")
                                }
                            )
                            .tabItem {
                                Label("Home", systemImage: "house")
                            }

                            ScanView(
                                selectedImage: .constant(nil),
                                username: username,
                                onPostCreated: { post in
                                    print("🔥 New post: \(post.catName)")
                                }
                            )
                            .tabItem {
                                Label("Post", systemImage: "plus.app")
                            }

                            ProfileView(
                                isLoggedIn: $isLoggedIn,
                                currentUsername: $username,
                                profileImage: $profileImage
                            )
                            .tabItem {
                                Label("Profile", systemImage: "person.crop.circle")
                            }
                        }
                        #if os(macOS)
                        .tabViewStyle(DefaultTabViewStyle()) // fixes TabContent issue
                        #endif
                    }
                } else {
                    LoginView(
                        isLoggedIn: $isLoggedIn,
                        username: $username,
                        profileImage: $profileImage
                    )
                }
            }
            .onAppear {
                autoLoginCheck()
            }
        }
    }

    // MARK: - Auto Login Logic
    private func autoLoginCheck() {
        if let user = Auth.auth().currentUser {
            isLoggedIn = true
            username = user.displayName ?? "User"
            loadUserProfile(userID: user.uid)
        } else {
            isLoggedIn = false
        }
    }

    // MARK: - Load User Profile (PFP)
    private func loadUserProfile(userID: String) {
        let db = Firestore.firestore()
        db.collection("users").document(userID).getDocument { doc, err in
            guard let data = doc?.data() else { return }
            if let name = data["displayName"] as? String {
                username = name
            }
            if let imageURL = data["profileImageURL"] as? String,
               let url = URL(string: imageURL),
               let imageData = try? Data(contentsOf: url) {
#if os(iOS)
                profileImage = UIImage(data: imageData)
#elseif os(macOS)
                profileImage = NSImage(data: imageData)
#endif
            }
        }
    }
}
