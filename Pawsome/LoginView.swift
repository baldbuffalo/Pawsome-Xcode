import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

struct LoginView: View {
    @Binding var isLoggedIn: Bool
    @Binding var username: String
    @Binding var profileImage: PlatformImage?

    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to Pawsome!")
                .font(.largeTitle)
                .bold()
                .padding()

            Text("Please sign in to continue")
                .font(.subheadline)
                .padding(.bottom, 50)

            Button(action: { universalSignIn() }) {
                Text("Sign In")
                    .bold()
                    .frame(width: 280, height: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }

            Spacer()
        }
        .alert("Sign-In Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Universal Sign-In
    private func universalSignIn() {
        Auth.auth().signInAnonymously { authResult, error in
            if let error = error {
                showErrorWithMessage("Login failed: \(error.localizedDescription)")
                return
            }

            guard let user = authResult?.user else {
                showErrorWithMessage("No user found after login.")
                return
            }

            let defaultUsername = "User\(Int.random(in: 1000...9999))"
            username = defaultUsername

            // Default profile image
            #if os(iOS)
            let defaultProfile = UIImage(systemName: "person.circle")
            #elseif os(macOS)
            let defaultProfile = NSImage(systemSymbolName: "person.circle", accessibilityDescription: nil)
            #endif
            profileImage = defaultProfile

            saveUserToFirestoreIfFirstTime(uid: user.uid)
        }
    }

    // MARK: - Firestore Save
    private func saveUserToFirestoreIfFirstTime(uid: String) {
        let userRef = Firestore.firestore().collection("users").document(uid)
        userRef.getDocument { snapshot, error in
            if let snapshot = snapshot, snapshot.exists {
                // Existing user, fetch data
                fetchUserData(uid: uid)
            } else {
                // First login, save new user
                var data: [String: Any] = [
                    "username": username,
                    "joinDate": Timestamp(date: Date())
                ]

                // Optionally upload default profile pic to Storage
                uploadDefaultProfileImage { url in
                    if let url = url { data["profileImageURL"] = url.absoluteString }

                    userRef.setData(data) { error in
                        if let error = error {
                            print("❌ Failed saving user: \(error.localizedDescription)")
                        } else {
                            print("✅ New user saved to Firestore.")
                        }
                        finishLogin()
                    }
                }
            }
        }
    }

    private func fetchUserData(uid: String) {
        let userRef = Firestore.firestore().collection("users").document(uid)
        userRef.getDocument { snapshot, error in
            if let data = snapshot?.data() {
                username = data["username"] as? String ?? username
                if let profileURLStr = data["profileImageURL"] as? String, let url = URL(string: profileURLStr) {
                    downloadImageFromURL(url: url) { img in
                        profileImage = img
                        finishLogin()
                    }
                } else {
                    finishLogin()
                }
            } else {
                finishLogin()
            }
        }
    }

    private func finishLogin() {
        UserDefaults.standard.set(username, forKey: "username")
        UserDefaults.standard.set(true, forKey: "isLoggedIn")
        isLoggedIn = true
    }

    private func showErrorWithMessage(_ msg: String) {
        errorMessage = msg
        showError = true
    }

    // MARK: - Upload/Download Helpers
    private func uploadDefaultProfileImage(completion: @escaping (URL?) -> Void) {
        guard let image = profileImage else { completion(nil); return }
        let storageRef = Storage.storage().reference().child("profilePictures/\(UUID().uuidString).png")
        var imageData: Data?
        #if os(iOS)
        imageData = image.pngData()
        #elseif os(macOS)
        if let tiff = image.tiffRepresentation {
            imageData = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:])
        }
        #endif
        guard let data = imageData else { completion(nil); return }

        storageRef.putData(data, metadata: nil) { _, error in
            if let error = error { print("❌ Upload error: \(error.localizedDescription)"); completion(nil); return }
            storageRef.downloadURL { url, _ in
                completion(url)
            }
        }
    }

    private func downloadImageFromURL(url: URL, completion: @escaping (PlatformImage?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, _, _ in
            var img: PlatformImage? = nil
            if let data = data {
                #if os(iOS)
                img = UIImage(data: data)
                #elseif os(macOS)
                img = NSImage(data: data)
                #endif
            }
            DispatchQueue.main.async { completion(img) }
        }.resume()
    }
}
