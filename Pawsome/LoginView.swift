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

            // MARK: – Google Sign-In
            Button {
                Task { await signInWithGoogle() }
            } label: {
                HStack {
                    Image(systemName: "globe")
                    Text("Sign in with Google")
                        .bold()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(8)
            }

            // MARK: – Apple Sign-In
            #if canImport(AuthenticationServices)
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]

                let nonce = randomNonceString()
                currentNonce = nonce
                request.nonce = sha256(nonce)

            } onCompletion: { result in
                Task { await handleAppleSignIn(result: result) }
            }
            .frame(height: 50)
            .padding(.top)
            #endif

            Spacer()
        }
        .padding()
        .alert("Sign-In Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: { Text(errorMessage) }
    }

    // MARK: - GOOGLE SIGN-IN
    private func signInWithGoogle() async {
        #if os(iOS)
        guard let rootVC = UIApplication.shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.keyWindow?.rootViewController })
            .first else { return }

        guard let clientID = FirebaseApp.app()?.options.clientID else {
            await showErrorWithMessage("Missing Google Client ID.")
            return
        }

        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
            let user = result.user

            username = user.profile?.name ?? "User\(Int.random(in: 1000...9999))"
            profileImage = user.profile?.imageURL(withDimension: 200)?.absoluteString
            saveLocally()

            guard let idToken = user.idToken?.tokenString else {
                await showErrorWithMessage("Missing Google ID token.")
                return
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: user.accessToken.tokenString
            )

            let authResult = try await Auth.auth().signIn(with: credential)
            saveUserToFirestore(uid: authResult.user.uid)

        } catch {
            await showErrorWithMessage("Google Sign-In failed: \(error.localizedDescription)")
        }
        #endif
    }

    // MARK: - APPLE SIGN-IN
    #if canImport(AuthenticationServices)
    private func handleAppleSignIn(result: Result<ASAuthorization, Error>) async {
        do {
            switch result {
            case .success(let auth):

                guard let credential = auth.credential as? ASAuthorizationAppleIDCredential else {
                    await showErrorWithMessage("Invalid Apple credential.")
                    return
                }

                username = credential.fullName?.givenName ?? "User\(Int.random(in: 1000...9999))"
                profileImage = nil
                saveLocally()

                guard let nonce = currentNonce else { return }
                guard let tokenData = credential.identityToken,
                      let idTokenString = String(data: tokenData, encoding: .utf8) else {
                    await showErrorWithMessage("Unable to fetch identity token.")
                    return
                }

                let firebaseCredential = OAuthProvider.credential(
                    providerID: AuthProviderID.apple,
                    idToken: idTokenString,
                    rawNonce: nonce
                )

                let authResult = try await Auth.auth().signIn(with: firebaseCredential)
                saveUserToFirestore(uid: authResult.user.uid)

            case .failure(let error):
                await showErrorWithMessage("Apple Sign-In failed: \(error.localizedDescription)")
            }

        } catch {
            await showErrorWithMessage("Apple Sign-In failed: \(error.localizedDescription)")
        }
    }
    #endif

    // MARK: - HELPERS

    private func saveLocally() {
        isLoggedIn = true
        UserDefaults.standard.set(true, forKey: "isLoggedIn")
        UserDefaults.standard.set(username, forKey: "username")
        UserDefaults.standard.set(profileImage ?? "", forKey: "profileImageURL")
    }

    private func saveUserToFirestore(uid: String) {
        let db = Firestore.firestore()
        db.collection("users").document(uid).setData([
            "username": username,
            "profileImageURL": profileImage ?? ""
        ], merge: true)
    }

    private func showErrorWithMessage(_ msg: String) async {
        await MainActor.run {
            errorMessage = msg
            showError = true
        }
    }

    private func randomNonceString(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return (0..<length).map { _ in String(charset.randomElement()!) }.joined()
    }

    private func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        return SHA256.hash(data: data).compactMap {
            String(format: "%02x", $0)
        }.joined()
    }
}
