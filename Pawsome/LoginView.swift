import SwiftUI
import AuthenticationServices
import GoogleSignIn
import FirebaseAuth
import FirebaseFirestore
import CryptoKit

#if canImport(UIKit)
import UIKit
#endif

struct LoginView: View {
    @Binding var isLoggedIn: Bool
    @Binding var username: String
    @Binding var profileImage: String?

    @State private var currentNonce: String?
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to Pawsome!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()

            Text("Please sign in to continue")
                .font(.subheadline)
                .padding(.bottom, 50)

            // Apple Sign-In Button
            SignInWithAppleButton(
                onRequest: { request in
                    let nonce = randomNonceString()
                    currentNonce = nonce
                    request.requestedScopes = [.fullName, .email]
                    request.nonce = sha256(nonce)
                },
                onCompletion: { result in
                    switch result {
                    case .success(let authResults):
                        handleAppleSignIn(result: authResults)
                    case .failure(let error):
                        errorMessage = "Apple Sign-In failed: \(error.localizedDescription)"
                        showError = true
                    }
                }
            )
            .signInWithAppleButtonStyle(.black)
            .frame(height: 50)
            .padding(.horizontal, 40)

            // Google Sign-In
            #if canImport(UIKit)
            Button(action: {
                googleSignIn()
            }) {
                HStack {
                    Image(systemName: "globe")
                    Text("Sign in with Google")
                        .fontWeight(.semibold)
                }
                .frame(width: 280, height: 50)
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(8)
                .padding(.horizontal, 40)
            }
            #endif

            Spacer()

            if isLoggedIn {
                NavigationLink(destination: ProfileView(isLoggedIn: $isLoggedIn, currentUsername: $username, profileImage: $profileImage)) {
                    Text("Go to Profile")
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                        .padding()
                }
            }
        }
        .alert("Sign-In Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Apple Sign-In
    private func handleAppleSignIn(result: ASAuthorization) {
        if let appleIDCredential = result.credential as? ASAuthorizationAppleIDCredential {
            guard let identityToken = appleIDCredential.identityToken,
                  let tokenString = String(data: identityToken, encoding: .utf8),
                  let nonce = currentNonce else {
                errorMessage = "Unable to fetch identity token or nonce"
                showError = true
                return
            }

            let credential = OAuthProvider.credential(
                providerID: .apple,
                idToken: tokenString,
                rawNonce: nonce
            )

            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    errorMessage = "Firebase Apple Sign-In failed: \(error.localizedDescription)"
                    showError = true
                    return
                }

                guard let user = authResult?.user else {
                    errorMessage = "No Firebase user found"
                    showError = true
                    return
                }

                if let fullName = appleIDCredential.fullName {
                    username = "\(fullName.givenName ?? "") \(fullName.familyName ?? "")"
                } else {
                    username = "Apple User"
                }

                profileImage = "system:person.circle"

                // ✅ Save to Firestore & local cache
                saveUserToFirestore(uid: user.uid, username: username, profileImage: profileImage)
                saveJoinDate()
                UserDefaults.standard.set(username, forKey: "username")
                UserDefaults.standard.set(true, forKey: "isLoggedIn")

                isLoggedIn = true
            }
        } else {
            errorMessage = "Apple credentials were not found."
            showError = true
        }
    }

    // MARK: - Google Sign-In
    private func googleSignIn() {
        #if canImport(UIKit)
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = scene.windows.first?.rootViewController else {
            errorMessage = "Could not find root view controller"
            showError = true
            return
        }

        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
            DispatchQueue.main.async {
                if let error = error {
                    errorMessage = "Google Sign-In failed: \(error.localizedDescription)"
                    showError = true
                } else if let user = result?.user {
                    handleGoogleSignIn(user: user)
                } else {
                    errorMessage = "Google Sign-In returned no user."
                    showError = true
                }
            }
        }
        #else
        errorMessage = "Google Sign-In is only supported on iOS."
        showError = true
        #endif
    }

    private func handleGoogleSignIn(user: GIDGoogleUser) {
        username = user.profile?.name ?? "No Name"
        if let profileURL = user.profile?.imageURL(withDimension: 100) {
            profileImage = profileURL.absoluteString
        }

        if let uid = Auth.auth().currentUser?.uid {
            saveUserToFirestore(uid: uid, username: username, profileImage: profileImage)
        }

        saveJoinDate()
        UserDefaults.standard.set(username, forKey: "username")
        UserDefaults.standard.set(true, forKey: "isLoggedIn")
        isLoggedIn = true
    }

    // MARK: - Firestore
    private func saveUserToFirestore(uid: String, username: String, profileImage: String?) {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(uid)

        var data: [String: Any] = [
            "username": username,
            "joinDate": Timestamp(date: Date())
        ]

        if let profileImage = profileImage {
            data["profileImage"] = profileImage
        }

        userRef.setData(data, merge: true) { error in
            if let error = error {
                print("❌ Error saving user: \(error.localizedDescription)")
            } else {
                print("✅ User document saved successfully.")
            }
        }
    }

    // MARK: - Save Join Date
    private func saveJoinDate() {
        if UserDefaults.standard.string(forKey: "joinDate") == nil {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            let joinDate = dateFormatter.string(from: Date())
            UserDefaults.standard.set(joinDate, forKey: "joinDate")
        }
    }

    // MARK: - Nonce Utils
    private func randomNonceString(length: Int = 32) -> String {
        let charset: Array<Character> =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }

            randoms.forEach { random in
                if remainingLength == 0 { return }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.map { String(format: "%02x", $0) }.joined()
    }
}
