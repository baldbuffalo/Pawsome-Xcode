import SwiftUI
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

            // MARK: - Google Sign-In
            Button("Sign in with Google") {
                Task { await signInWithGoogle() }
            }
            .padding()
            .foregroundColor(.white)
            .background(Color.red)
            .cornerRadius(8)

            // MARK: - Apple Sign-In
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

    // MARK: - Google Sign-In (local only)
    private func signInWithGoogle() async {
        #if os(iOS)
        guard let rootVC = UIApplication.shared.connectedScenes
                .compactMap({ ($0 as? UIWindowScene)?.keyWindow?.rootViewController })
                .first else { return }
        do {
            let signInResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
            let gidUser = signInResult.user
            username = gidUser.profile?.name ?? "User\(Int.random(in: 1000...9999))"
            profileImage = gidUser.profile?.imageURL(withDimension: 200)?.absoluteString
            saveLocally()
        } catch {
            await showErrorWithMessage("Google Sign-In failed: \(error.localizedDescription)")
        }
        #elseif os(macOS)
        guard let window = NSApp.keyWindow else { return }
        do {
            let signInResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: window)
            let gidUser = signInResult.user
            username = gidUser.profile?.name ?? "User\(Int.random(in: 1000...9999))"
            profileImage = gidUser.profile?.imageURL(withDimension: 200)?.absoluteString
            saveLocally()
        } catch {
            await showErrorWithMessage("Google Sign-In failed: \(error.localizedDescription)")
        }
        #endif
    }

    // MARK: - Apple Sign-In (local only)
    #if canImport(AuthenticationServices)
    private func handleAppleSignIn(result: Result<ASAuthorization, Error>) async {
        do {
            switch result {
            case .success(let auth):
                if let credential = auth.credential as? ASAuthorizationAppleIDCredential {
                    username = credential.fullName?.givenName ?? "User\(Int.random(in: 1000...9999))"
                    profileImage = nil
                    saveLocally()
                }
            case .failure(let error):
                await showErrorWithMessage("Apple Sign-In failed: \(error.localizedDescription)")
            }
        } catch {
            await showErrorWithMessage("Apple Sign-In failed: \(error.localizedDescription)")
        }
    }
    #endif

    // MARK: - Helpers
    private func saveLocally() {
        isLoggedIn = true
        UserDefaults.standard.set(true, forKey: "isLoggedIn")
        UserDefaults.standard.set(username, forKey: "username")
        UserDefaults.standard.set(profileImage ?? "", forKey: "profileImageURL")
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
        let inputData = Data(input.utf8)
        return SHA256.hash(data: inputData).map { String(format: "%02x", $0) }.joined()
    }
}
