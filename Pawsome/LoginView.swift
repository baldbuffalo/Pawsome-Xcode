import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseCore
import GoogleSignIn
#if os(iOS)
import AuthenticationServices
#endif

struct LoginView: View {
    @Binding var isLoggedIn: Bool
    @Binding var username: String
    @Binding var profileImage: String?

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

            // Anonymous Sign-In
            Button("Sign in Anonymously") { Task { await universalSignIn(authType: .anonymous) } }

            // Google Sign-In
            Button("Sign in with Google") { Task { await universalSignIn(authType: .google) } }

            // Apple Sign-In (iOS only)
            #if os(iOS)
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
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
    enum AuthType { case anonymous, google }

    // MARK: - Universal Sign-In
    private func universalSignIn(authType: AuthType) async {
        do {
            let user: User

            switch authType {
            case .anonymous:
                let result = try await Auth.auth().signInAnonymously()
                user = result.user
                username = "User\(Int.random(in: 1000...9999))"
                profileImage = nil

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
                guard let idToken = gidUser.idToken?.tokenString,
                      let accessToken = gidUser.accessToken?.tokenString else {
                    await showErrorWithMessage("Google auth tokens missing")
                    return
                }

                let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
                let result = try await Auth.auth().signIn(with: credential)
                user = result.user

                username = gidUser.profile?.name ?? "User\(Int.random(in: 1000...9999))"
                profileImage = gidUser.profile?.imageURL(withDimension: 200)?.absoluteString
            }

            // Save user to Firestore
            try await saveUserToFirestore(uid: user.uid)

            // Login success
            UserDefaults.standard.set(username, forKey: "username")
            UserDefaults.standard.set(true, forKey: "isLoggedIn")
            isLoggedIn = true

        } catch {
            await showErrorWithMessage("Login failed: \(error.localizedDescription)")
        }
    }

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

    private func showErrorWithMessage(_ msg: String) async {
        await MainActor.run {
            errorMessage = msg
            showError = true
        }
    }

    #if os(iOS)
    private func handleAppleSignIn(result: Result<ASAuthorization, Error>) async {
        do {
            switch result {
            case .success(let auth):
                if let credential = auth.credential as? ASAuthorizationAppleIDCredential {
                    let token = credential.identityToken
                    let idTokenString = String(data: token!, encoding: .utf8)!
                    let appleCredential = OAuthProvider.credential(withProviderID: "apple.com", idToken: idTokenString, rawNonce: nil)
                    let result = try await Auth.auth().signIn(with: appleCredential)
                    let user = result.user

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
}
