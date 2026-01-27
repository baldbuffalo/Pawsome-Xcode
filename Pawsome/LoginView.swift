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
                colors: [
                    Color.blue.opacity(0.25),
                    Color.purple.opacity(0.25),
                    Color.pink.opacity(0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {

                Spacer()

                // 🐾 LOGO / TITLE
                VStack(spacing: 12) {
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(.linearGradient(
                            colors: [.pink, .purple],
                            startPoint: .top,
                            endPoint: .bottom
                        ))

                    Text("Pawsome")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Find. Help. Reunite.")
                        .foregroundColor(.secondary)
                }

                // 🔐 AUTH CARD
                VStack(spacing: 16) {

                    // 🔴 GOOGLE SIGN IN
                    Button {
                        Task { await signInWithGoogle() }
                    } label: {
                        HStack(spacing: 12) {
                            Image("google") // optional asset
                                .resizable()
                                .frame(width: 20, height: 20)
                                .opacity(0.9)

                            Text("Continue with Google")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(14)
                        .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
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
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 52)
                    .cornerRadius(14)
                    #endif
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.15), radius: 20)
                )
                .padding(.horizontal)

                Spacer()
            }
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
                await showError("No window found.")
                return
            }

            result = try await GIDSignIn.sharedInstance
                .signIn(withPresenting: window)
            #endif

            let user = result.user

            guard let idToken = user.idToken?.tokenString else {
                await showError("Missing Google ID token.")
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
                googleImageURL: user.profile?
                    .imageURL(withDimension: 200)?
                    .absoluteString
            )

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
        let charset = Array(
            "0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._"
        )
        return String((0..<length).compactMap { _ in charset.randomElement() })
    }

    private func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }
}
