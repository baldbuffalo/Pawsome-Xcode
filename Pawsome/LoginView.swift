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

#if os(macOS)
import AppKit
#endif

struct LoginView: View {

    @ObservedObject var appState: PawsomeApp.AppState

    @State private var showError = false
    @State private var errorMessage = ""
    @State private var currentNonce: String?

    var body: some View {
        ZStack {
            // 🌈 BACKGROUND
            LinearGradient(
                colors: [.purple, .blue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {

                VStack(spacing: 10) {
                    Text("🐾 Pawsome")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)

                    Text("Find. Help. Reunite.")
                        .foregroundColor(.white.opacity(0.8))
                }

                // 🔴 GOOGLE SIGN IN
                Button {
                    Task { await signInWithGoogle() }
                } label: {
                    HStack {
                        Image(systemName: "globe")
                        Text("Continue with Google").bold()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .foregroundColor(.black)
                    .cornerRadius(14)
                    .shadow(radius: 8)
                }

                // 🍎 APPLE SIGN IN
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
                .cornerRadius(14)
                .shadow(radius: 8)
                #endif
            }
            .padding()
            .frame(maxWidth: 420)
        }
        .alert("Sign-In Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - GOOGLE SIGN IN
    private func signInWithGoogle() async {

        guard let clientID = FirebaseApp.app()?.options.clientID else {
            await showError("Missing Google client ID.")
            return
        }

        GIDSignIn.sharedInstance.configuration =
            GIDConfiguration(clientID: clientID)

        do {
            let result: GIDSignInResult

            #if os(iOS)
            guard
                let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                let rootVC = scene.windows.first?.rootViewController
            else {
                await showError("No root view controller.")
                return
            }

            result = try await GIDSignIn.sharedInstance
                .signIn(withPresenting: rootVC)

            #elseif os(macOS)
            guard let window = NSApplication.shared.windows.first else {
                await showError("No window.")
                return
            }

            result = try await GIDSignIn.sharedInstance
                .signIn(withPresenting: window)
            #endif

            let user = result.user

            guard let idToken = user.idToken?.tokenString else {
                await showError("Missing Google token.")
                return
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: user.accessToken.tokenString
            )

            let authResult =
                try await Auth.auth().signIn(with: credential)

            await fetchUserAndLogin(
                uid: authResult.user.uid,
                defaultUsername: user.profile?.name,
                profileImageURL:
                    user.profile?.imageURL(withDimension: 200)?.absoluteString
            )

        } catch {
            await showError(error.localizedDescription)
        }
    }

    // MARK: - APPLE SIGN IN
    #if canImport(AuthenticationServices)
    private func handleAppleSignIn(
        _ result: Result<ASAuthorization, Error>
    ) async {

        do {
            guard
                case .success(let auth) = result,
                let credential =
                    auth.credential as? ASAuthorizationAppleIDCredential,
                let nonce = currentNonce,
                let tokenData = credential.identityToken,
                let idToken =
                    String(data: tokenData, encoding: .utf8)
            else {
                await showError("Apple Sign-In failed.")
                return
            }

            let firebaseCredential =
                OAuthProvider.credential(
                    providerID: AuthProviderID.apple,
                    idToken: idToken,
                    rawNonce: nonce
                )

            let authResult =
                try await Auth.auth().signIn(
                    with: firebaseCredential
                )

            await fetchUserAndLogin(
                uid: authResult.user.uid,
                defaultUsername:
                    credential.fullName?.givenName,
                profileImageURL: nil
            )

        } catch {
            await showError(error.localizedDescription)
        }
    }
    #endif

    // MARK: - FIRESTORE USER SETUP (🔥 FIXED)
    private func fetchUserAndLogin(
        uid: String,
        defaultUsername: String?,
        profileImageURL: String?
    ) async {

        let db = Firestore.firestore()
        let userRef = db.collection("users").document(uid)
        let counterRef = db.collection("counter").document("users")

        do {
            let snap = try await userRef.getDocument()

            // ✅ EXISTING USER
            if snap.exists {
                let data = snap.data() ?? [:]
                await MainActor.run {
                    appState.isLoggedIn = true
                    appState.currentUsername =
                        data["username"] as? String ?? "User"
                    appState.profileImageURL =
                        data["profilePic"] as? String
                }
                return
            }

            // 🔥 NEW USER (TRANSACTION FIX)
            let nextUserNumber = try await db.runTransaction {
                transaction, errorPointer in

                do {
                    let counterSnap =
                        try transaction.getDocument(counterRef)

                    let last =
                        counterSnap.data()?["lastUserNumber"] as? Int ?? 0
                    let next = last + 1

                    transaction.updateData(
                        ["lastUserNumber": next],
                        forDocument: counterRef
                    )

                    transaction.setData([
                        "userNumber": next,
                        "username":
                            defaultUsername ?? "User\(next)",
                        "profilePic": profileImageURL ?? "",
                        "createdAt": Timestamp()
                    ], forDocument: userRef)

                    return next

                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }
            }

            guard let nextUserNumber else {
                throw NSError(domain: "Firestore", code: -1)
            }

            await MainActor.run {
                appState.isLoggedIn = true
                appState.currentUsername =
                    defaultUsername ?? "User\(nextUserNumber)"
                appState.profileImageURL =
                    profileImageURL
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
        let charset =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String((0..<length).compactMap { _ in charset.randomElement() })
    }

    private func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }
}
