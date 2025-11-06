import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseCore
import GoogleSignIn
import CryptoKit
#if canImport(AuthenticationServices)
import AuthenticationServices
#endif

struct LoginView: View {
    @Binding var isLoggedIn: Bool
    @Binding var username: String
    @Binding var profileImage: String?

    @State private var showError = false
    @State private var errorMessage = ""
    @State private var currentNonce: String? = nil

    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to Pawsome!")
                .font(.largeTitle)
                .bold()
                .padding()

            Text("Please sign in to continue")
                .font(.subheadline)
                .padding(.bottom, 50)

            // Google Sign-In
            Button("Sign in with Google") { Task { await universalSignIn(authType: .google) } }

            // Apple Sign-In
            #if canImport(AuthenticationServices)
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
                let nonce = randomNonceString()
                self.currentNonce = nonce
                request.nonce = sha256(nonce)
            } onCompletion: { result in
                Task { await handleAppleSignIn(result: result) }
            }
            .frame(height: 50)
            .padding(.top)
            #endif

            Spacer()
        }
        .alert("Sign-In Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: { Text(errorMessage) }
    }

    // MARK: - Auth Types
    enum AuthType { case google }

    // MARK: - Universal Sign-In
    private func universalSignIn(authType: AuthType) async {
        do {
            let user: User

            switch authType {
            case .google:
                #if os(iOS)
                guard let clientID = FirebaseApp.app()?.options.clientID else { return }
                let config = GIDConfiguration(clientID: clientID)
                guard let root = UIApplication.shared.windows.first?.rootViewController else { return }
                let signInResult = try await GIDSignIn.sharedInstance.signIn(for: config, presenting: root)
                #elseif os(macOS)
                guard let window = NSApp.keyWindow else { return }
                let signInResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: window)
                #endif

                let gidUser = signInResult.user

                #if os(iOS)
                // On iOS, idToken is optional; accessToken.tokenString is non-optional
                guard let idTokenString = gidUser.idToken?.tokenString else {
                    await showErrorWithMessage("Google ID token missing")
                    return
                }
                let accessTokenString = gidUser.accessToken.tokenString
                #elseif os(macOS)
                // On macOS, idToken is optional; accessToken.tokenString is non-optional in latest SDK
                guard let idTokenString = gidUser.idToken?.tokenString else {
                    await showErrorWithMessage("Google ID token missing")
                    return
                }
                let accessTokenString = gidUser.accessToken.tokenString
                #endif

                let credential = GoogleAuthProvider.credential(withIDToken: idTokenString,
                                                               accessToken: accessTokenString)
                let result = try await Auth.auth().signIn(with: credential)
                user = result.user

                // Safe profile info
                username = gidUser.profile?.name ?? "User\(Int.random(in: 1000...9999))"
                profileImage = gidUser.profile?.imageURL(withDimension: 200)?.absoluteString
            }

            // Save user to Firestore
            try await saveUserToFirestore(uid: user.uid)

            // Persist login locally
            UserDefaults.standard.set(username, forKey: "username")
            UserDefaults.standard.set(true, forKey: "isLoggedIn")
            isLoggedIn = true

        } catch {
            await showErrorWithMessage("Login failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Save user to Firestore
    private func saveUserToFirestore(uid: String) async throws {
        let userRef = Firestore.firestore().collection("users").document(uid)
        let snapshot = try await userRef.getDocument()

        if snapshot.exists { return }

        try await userRef.setData([
            "username": username,
            "profileImage": profileImage ?? "",
            "joinDate": Timestamp(date: Date())
        ])
        print("✅ User saved to Firestore.")
    }

    // MARK: - Error handler
    private func showErrorWithMessage(_ msg: String) async {
        await MainActor.run {
            errorMessage = msg
            showError = true
        }
    }

    // MARK: - Apple Sign-In
    #if canImport(AuthenticationServices)
    private func handleAppleSignIn(result: Result<ASAuthorization, Error>) async {
        do {
            switch result {
            case .success(let auth):
                if let credential = auth.credential as? ASAuthorizationAppleIDCredential {
                    guard let token = credential.identityToken,
                          let idTokenString = String(data: token, encoding: .utf8) else {
                        await showErrorWithMessage("Apple Sign-In failed: Unable to fetch identity token.")
                        return
                    }
                    guard let nonce = currentNonce else {
                        await showErrorWithMessage("Apple Sign-In failed: Missing login state (nonce).")
                        return
                    }
                    let appleCredential = OAuthProvider.credential(withProviderID: "apple.com",
                                                                   idToken: idTokenString,
                                                                   rawNonce: nonce)
                    let result = try await Auth.auth().signIn(with: appleCredential)
                    let user = result.user
                    self.currentNonce = nil

                    username = credential.fullName?.givenName ?? "User\(Int.random(in: 1000...9999))"
                    profileImage = nil

                    try await saveUserToFirestore(uid: user.uid)
                    UserDefaults.standard.set(username, forKey: "username")
                    UserDefaults.standard.set(true, forKey: "isLoggedIn")
                    isLoggedIn = true
                }
            case .failure(let error):
                await showErrorWithMessage("Apple Sign-In failed: \(error.localizedDescription)")
            }
        } catch {
            await showErrorWithMessage("Apple Sign-In failed: \(error.localizedDescription)")
        }
    }
    #endif

    // MARK: - Nonce helpers for Sign in with Apple
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var generator = SystemRandomNumberGenerator()
        for _ in 0..<length {
            result.append(charset.randomElement(using: &generator)!)
        }
        return result
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.map { String(format: "%02x", $0) }.joined()
    }
}
