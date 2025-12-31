import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseCore
import GoogleSignIn
import GoogleSignInSwift
import CryptoKit
#if canImport(AuthenticationServices)
import AuthenticationServices
#endif

struct LoginView: View {
    @ObservedObject var appState: PawsomeApp.AppState

    @State private var showError = false
    @State private var errorMessage = ""
    @State private var currentNonce: String?

    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to Pawsome!")
                .font(.largeTitle)
                .bold()

            Text("Please sign in to continue")
                .foregroundColor(.gray)

            // 🔴 GOOGLE SIGN-IN
            Button {
                Task { await signInWithGoogle() }
            } label: {
                HStack {
                    Image(systemName: "globe")
                    Text("Sign in with Google").bold()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
            }

            // 🍎 APPLE SIGN-IN
            #if canImport(AuthenticationServices)
            SignInWithAppleButton(.signIn) { request in
                let nonce = randomNonceString()
                currentNonce = nonce
                request.requestedScopes = [.fullName, .email]
                request.nonce = sha256(nonce)
            } onCompletion: { result in
                Task { await handleAppleSignIn(result) }
            }
            .frame(height: 50)
            #endif

            Spacer()
        }
        .padding()
        .alert("Sign-In Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - GOOGLE SIGN-IN
    private func signInWithGoogle() async {
        #if os(iOS)
        guard
            let clientID = FirebaseApp.app()?.options.clientID,
            let rootVC = UIApplication.shared.connectedScenes
                .compactMap({ ($0 as? UIWindowScene)?.keyWindow?.rootViewController })
                .first
        else {
            await showError("Google Sign-In setup failed.")
            return
        }

        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
            let user = result.user

            guard let idToken = user.idToken?.tokenString else {
                await showError("Missing Google ID token.")
                return
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: user.accessToken.tokenString
            )

            let authResult = try await Auth.auth().signIn(with: credential)

            await fetchUserAndLogin(
                uid: authResult.user.uid,
                defaultUsername: user.profile?.name,
                defaultImage: user.profile?.imageURL(withDimension: 200)?.absoluteString
            )
        } catch {
            await showError(error.localizedDescription)
        }
        #endif
    }

    // MARK: - APPLE SIGN-IN
    #if canImport(AuthenticationServices)
    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) async {
        do {
            guard
                case .success(let auth) = result,
                let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                let nonce = currentNonce,
                let tokenData = credential.identityToken,
                let idToken = String(data: tokenData, encoding: .utf8)
            else {
                await showError("Apple Sign-In failed.")
                return
            }

            let firebaseCredential = OAuthProvider.credential(
                providerID: AuthProviderID.apple,
                idToken: idToken,
                rawNonce: nonce
            )

            let authResult = try await Auth.auth().signIn(with: firebaseCredential)

            await fetchUserAndLogin(
                uid: authResult.user.uid,
                defaultUsername: credential.fullName?.givenName,
                defaultImage: nil
            )
        } catch {
            await showError(error.localizedDescription)
        }
    }
    #endif

    // MARK: - FIRESTORE USER FETCH
    private func fetchUserAndLogin(
        uid: String,
        defaultUsername: String?,
        defaultImage: String?
    ) async {
        let db = Firestore.firestore()

        do {
            let doc = try await db.collection("users").document(uid).getDocument()

            let username = doc.data()?["username"] as? String
                ?? defaultUsername
                ?? "User\(Int.random(in: 1000...9999))"

            let imageURL = doc.data()?["profileImageURL"] as? String ?? defaultImage

            await MainActor.run {
                appState.isLoggedIn = true
                appState.currentUsername = username
                appState.profileImageURL = imageURL

                UserDefaults.standard.set(true, forKey: "isLoggedIn")
                UserDefaults.standard.set(username, forKey: "username")
                if let imageURL {
                    UserDefaults.standard.set(imageURL, forKey: "profileImageURL")
                }
            }

            // Save defaults for new users
            if !doc.exists {
                try await db.collection("users").document(uid).setData([
                    "username": username,
                    "profileImageURL": imageURL ?? ""
                ])
            }

        } catch {
            await showError(error.localizedDescription)
        }
    }

    // MARK: - HELPERS
    private func showError(_ message: String) async {
        await MainActor.run {
            errorMessage = message
            showError = true
        }
    }

    private func randomNonceString(length: Int = 32) -> String {
        let chars = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String((0..<length).compactMap { _ in chars.randomElement() })
    }

    private func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }
}
