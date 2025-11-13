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
                .font(.largeTitle).bold().padding()
            Text("Please sign in to continue")
                .font(.subheadline).padding(.bottom, 50)

            Button("Sign in with Google") {
                Task { await universalSignIn(authType: .google) }
            }

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

    enum AuthType { case google }

    private func universalSignIn(authType: AuthType) async {
        guard FirebaseApp.app() != nil else {
            await showErrorWithMessage("Firebase not configured yet")
            return
        }

        do {
            let user: User
            switch authType {
            case .google:
                #if os(iOS)
                guard let rootVC = UIApplication.shared.connectedScenes
                        .compactMap({ ($0 as? UIWindowScene)?.keyWindow?.rootViewController })
                        .first else { return }
                let signInResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
                let gidUser = signInResult.user
                guard let idToken = gidUser.idToken?.tokenString else { return }
                let credential = GoogleAuthProvider.credential(
                    withIDToken: idToken,
                    accessToken: gidUser.accessToken.tokenString
                )
                let result = try await Auth.auth().signIn(with: credential)
                user = result.user
                username = gidUser.profile?.name ?? "User\(Int.random(in:1000...9999))"
                profileImage = gidUser.profile?.imageURL(withDimension: 200)?.absoluteString
                #elseif os(macOS)
                guard let window = NSApp.keyWindow else { return }
                let signInResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: window)
                let gidUser = signInResult.user
                guard let idToken = gidUser.idToken?.tokenString else { return }
                let credential = GoogleAuthProvider.credential(
                    withIDToken: idToken,
                    accessToken: gidUser.accessToken.tokenString
                )
                let result = try await Auth.auth().signIn(with: credential)
                user = result.user
                username = gidUser.profile?.name ?? "User\(Int.random(in:1000...9999))"
                profileImage = gidUser.profile?.imageURL(withDimension: 200)?.absoluteString
                #endif
            }

            try await saveUserToFirestore(uid: user.uid)
            UserDefaults.standard.set(username, forKey: "username")
            UserDefaults.standard.set(true, forKey: "isLoggedIn")
            isLoggedIn = true
        } catch {
            await showErrorWithMessage("Login failed: \(error.localizedDescription)")
        }
    }

    private func saveUserToFirestore(uid: String) async throws {
        guard FirebaseApp.app() != nil else { return }
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(uid)
        let snapshot = try await userRef.getDocument()

        var data: [String: Any] = [
            "username": username,
            "profileImage": profileImage ?? "",
            "lastLogin": Timestamp(date: Date()),
            "uid": uid
        ]

        if let currentUser = Auth.auth().currentUser {
            data["email"] = currentUser.email ?? ""
            data["displayName"] = currentUser.displayName ?? username
            data["providerIDs"] = currentUser.providerData.map { $0.providerID }
        }

        if snapshot.exists {
            try await userRef.setData(data, merge: true)
            print("✅ Existing user updated in Firestore")
        } else {
            data["joinDate"] = Timestamp(date: Date())
            try await userRef.setData(data, merge: true)
            print("✅ New user created in Firestore")
        }
    }

    private func showErrorWithMessage(_ msg: String) async {
        await MainActor.run {
            errorMessage = msg
            showError = true
        }
    }

    #if canImport(AuthenticationServices)
    private func handleAppleSignIn(result: Result<ASAuthorization, Error>) async {
        guard FirebaseApp.app() != nil else { return }

        do {
            switch result {
            case .success(let auth):
                if let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                   let token = credential.identityToken,
                   let idTokenString = String(data: token, encoding: .utf8),
                   let nonce = currentNonce {

                    let appleCredential = OAuthProvider.credential(
                        providerID: AuthProviderID.apple,
                        idToken: idTokenString,
                        rawNonce: nonce
                    )

                    let res = try await Auth.auth().signIn(with: appleCredential)
                    let user = res.user
                    self.currentNonce = nil
                    username = credential.fullName?.givenName ?? "User\(Int.random(in:1000...9999))"
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

    private func randomNonceString(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return (0..<length).map { _ in String(charset.randomElement()!) }.joined()
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        return SHA256.hash(data: inputData).map { String(format: "%02x", $0) }.joined()
    }
}
