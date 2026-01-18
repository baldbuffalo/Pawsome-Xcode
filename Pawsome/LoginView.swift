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

    #if os(macOS)
    @State private var googleAuthSession: ASWebAuthenticationSession?
    #endif

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
            .frame(width: 300, height: 50)
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
            try await handleGoogleResult(result.user)
        } catch {
            await showError(error.localizedDescription)
        }
        #elseif os(macOS)
        // macOS Google Sign-In
        do {
            try await signInWithGoogleMacOS()
        } catch {
            await showError(error.localizedDescription)
        }
        #endif
    }

    #if os(macOS)
    private func signInWithGoogleMacOS() async throws {
        guard
            let clientID = Bundle.main.object(forInfoDictionaryKey: "GoogleClientID") as? String,
            let clientSecret = Bundle.main.object(forInfoDictionaryKey: "GoogleClientSecret") as? String
        else {
            await showError("Missing Google credentials")
            return
        }

        let redirectURI = "com.googleusercontent.apps.\(clientID.split(separator: "-").first!):/oauthredirect"

        let authURL = URL(string:
            "https://accounts.google.com/o/oauth2/v2/auth?" +
            "client_id=\(clientID)&" +
            "redirect_uri=\(redirectURI)&" +
            "response_type=code&" +
            "scope=openid%20email%20profile"
        )!

        googleAuthSession = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: redirectURI
        ) { callbackURL, _ in
            guard
                let callbackURL,
                let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
                let code = components.queryItems?.first(where: { $0.name == "code" })?.value
            else {
                Task { await showError("Google Sign-In canceled.") }
                return
            }

            Task {
                do {
                    try await exchangeGoogleCodeForFirebase(
                        code: code,
                        clientID: clientID,
                        clientSecret: clientSecret,
                        redirectURI: redirectURI
                    )
                } catch {
                    await showError(error.localizedDescription)
                }
            }
        }

        googleAuthSession?.prefersEphemeralWebBrowserSession = true
        googleAuthSession?.start()
    }

    private func exchangeGoogleCodeForFirebase(
        code: String,
        clientID: String,
        clientSecret: String,
        redirectURI: String
    ) async throws {
        var request = URLRequest(url: URL(string: "https://oauth2.googleapis.com/token")!)
        request.httpMethod = "POST"
        request.httpBody = "code=\(code)&client_id=\(clientID)&client_secret=\(clientSecret)&redirect_uri=\(redirectURI)&grant_type=authorization_code".data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        guard
            let idToken = json?["id_token"] as? String,
            let accessToken = json?["access_token"] as? String
        else {
            throw NSError(domain: "GoogleSignIn", code: 0)
        }

        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        let result = try await Auth.auth().signIn(with: credential)

        await fetchUserAndLogin(uid: result.user.uid, defaultUsername: nil, defaultImage: nil)
    }
    #endif

    private func handleGoogleResult(_ user: GIDGoogleUser) async throws {
        guard let idToken = user.idToken?.tokenString else {
            await showError("Missing Google ID token.")
            return
        }

        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: user.accessToken.tokenString
        )

        let result = try await Auth.auth().signIn(with: credential)

        await fetchUserAndLogin(
            uid: result.user.uid,
            defaultUsername: user.profile?.name,
            defaultImage: user.profile?.imageURL(withDimension: 200)?.absoluteString
        )
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

            let result = try await Auth.auth().signIn(with: firebaseCredential)

            await fetchUserAndLogin(
                uid: result.user.uid,
                defaultUsername: credential.fullName?.givenName,
                defaultImage: nil
            )
        } catch {
            await showError(error.localizedDescription)
        }
    }
    #endif

    // MARK: - FIRESTORE (✅ Async/Await Transaction)
    private func fetchUserAndLogin(
        uid: String,
        defaultUsername: String?,
        defaultImage: String?
    ) async {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(uid)
        let counterRef = db.collection("counter").document("users")

        do {
            let userDoc = try await userRef.getDocument()

            if userDoc.exists {
                let data = userDoc.data() ?? [:]
                await MainActor.run {
                    appState.isLoggedIn = true
                    appState.currentUsername = data["username"] as? String ?? "User"
                    appState.profileImageURL = data["profilePic"] as? String
                }
                return
            }

            // New user → atomic counter
            let newUserNumber = try await db.runTransaction { transaction in
                let counterDoc = try await transaction.getDocument(counterRef)
                let last = counterDoc.data()?["lastUserNumber"] as? Int ?? 0
                let next = last + 1
                transaction.updateData(["lastUserNumber": next], forDocument: counterRef)
                return next
            }

            let username = defaultUsername ?? "User\(newUserNumber)"
            let profilePic = defaultImage ?? ""

            try await userRef.setData([
                "userNumber": newUserNumber,
                "username": username,
                "profilePic": profilePic,
                "createdAt": Timestamp()
            ])

            await MainActor.run {
                appState.isLoggedIn = true
                appState.currentUsername = username
                appState.profileImageURL = profilePic
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
