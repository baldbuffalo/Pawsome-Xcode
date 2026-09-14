import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import GoogleSignInSwift

struct LoginView: View {
    @ObservedObject var appState: PawsomeApp.AppState
    @State private var isLoadingGoogle = false
    @State private var isLoadingTwitter = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.purple.opacity(0.10), Color(.systemBackground), Color.blue.opacity(0.05)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack {
                HStack { Spacer(); Text("🐾").font(.system(size: 100)).padding(.top, 60).padding(.trailing, 24) }
                Spacer()
            }

            HStack {
                Text("🐾").font(.system(size: 70)).padding(.leading, 24).padding(.bottom, 100)
                Spacer()
            }

            VStack(spacing: 20) {
                ZStack {
                    RoundedRectangle(cornerRadius: 24).fill(LinearGradient(colors: [.orange, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                    Image(systemName: "pawprint.fill").font(.system(size: 54)).foregroundStyle(.white)
                }
                .frame(width: 100, height: 100)

                Text("🐱 Pawsome").font(.largeTitle.bold())
                Text("Help lost cats find their way home")
                    .font(.body).foregroundStyle(.secondary).multilineTextAlignment(.center)
                Spacer().frame(height: 4)

                Button {
                    Task { isLoadingGoogle = true; await signInWithGoogle(); isLoadingGoogle = false }
                } label: {
                    HStack {
                        if isLoadingGoogle { ProgressView().tint(.gray) }
                        else { Image(systemName: "g.circle").font(.title2) }
                        Text("Continue with Google").foregroundStyle(.primary).fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity, minHeight: 56)
                }
                .buttonStyle(.borderedProminent)
                .tint(.white)
                .disabled(isLoadingGoogle || isLoadingTwitter)

                Button {
                    Task { isLoadingTwitter = true; await signInWithTwitter(); isLoadingTwitter = false }
                } label: {
                    HStack {
                        if isLoadingTwitter { ProgressView().tint(.white) }
                        else { Text("𝕏").font(.title2.bold()) }
                        Text("Continue with X").foregroundStyle(.white).fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(Color.black, in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .disabled(isLoadingGoogle || isLoadingTwitter)

                if let errorMessage {
                    Text(errorMessage).font(.caption).foregroundStyle(.red).multilineTextAlignment(.center)
                }
            }
            .padding(32)
            .frame(maxWidth: 400)
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 28))
            .shadow(radius: 8)
            .padding(24)
        }
    }

    private func signInWithGoogle() async {
        guard let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String, !clientID.isEmpty else {
            errorMessage = "Missing Google client ID."
            return
        }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        do {
            #if os(iOS)
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootVC = scene.windows.first?.rootViewController else { throw NSError(domain: "Pawsome", code: 1, userInfo: [NSLocalizedDescriptionKey: "No root view controller."]) }
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
            #else
            guard let window = NSApplication.shared.windows.first else { throw NSError(domain: "Pawsome", code: 1, userInfo: [NSLocalizedDescriptionKey: "No window."]) }
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: window)
            #endif
            guard let idToken = result.user.idToken?.tokenString else { throw NSError(domain: "Pawsome", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing Google token."]) }
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: result.user.accessToken.tokenString)
            let authResult = try await Auth.auth().signIn(with: credential)
            await appState.fetchOrCreateUser(uid: authResult.user.uid, defaultUsername: result.user.profile?.name, defaultImage: result.user.profile?.imageURL(withDimension: 200)?.absoluteString)
        } catch { errorMessage = error.localizedDescription }
    }

    private func signInWithTwitter() async {
        do {
            let provider = OAuthProvider(providerID: "twitter.com")
            let credential = try await provider.credential(with: nil)
            let result = try await Auth.auth().signIn(with: credential)
            await appState.fetchOrCreateUser(uid: result.user.uid, defaultUsername: result.user.displayName, defaultImage: result.user.photoURL?.absoluteString)
        } catch { errorMessage = error.localizedDescription }
    }
}
