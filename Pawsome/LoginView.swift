import SwiftUI
import AuthenticationServices
import GoogleSignIn
import FirebaseAuth
import FirebaseFirestore

#if canImport(UIKit)
import UIKit
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
                .fontWeight(.bold)
                .padding()

            Text("Please sign in to continue")
                .font(.subheadline)
                .padding(.bottom, 50)

            // Apple Sign-In
            SignInWithAppleButton(
                onRequest: { request in
                    request.requestedScopes = [.fullName, .email]
                },
                onCompletion: { result in
                    switch result {
                    case .success(let authResults):
                        handleAppleSignIn(result: authResults)
                    case .failure(let error):
                        errorMessage = "Apple Sign-In failed: \(error.localizedDescription)"
                        showError = true
                    }
                }
            )
            .signInWithAppleButtonStyle(.black)
            .frame(height: 50)
            .padding(.horizontal, 40)

            // Google Sign-In
            #if canImport(UIKit)
            Button(action: {
                googleSignIn()
            }) {
                HStack {
                    Image(systemName: "globe")
                    Text("Sign in with Google")
                        .fontWeight(.semibold)
                }
                .frame(width: 280, height: 50)
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(8)
                .padding(.horizontal, 40)
            }
            #endif

            Spacer()

            if isLoggedIn {
                NavigationLink(destination: ProfileView(isLoggedIn: $isLoggedIn, currentUsername: $username, profileImage: $profileImage)) {
                    Text("Go to Profile")
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                        .padding()
                }
            }
        }
        .alert("Sign-In Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Apple Sign-In
    private func handleAppleSignIn(result: ASAuthorization) {
        if let appleIDCredential = result.credential as? ASAuthorizationAppleIDCredential {
            guard let identityToken = appleIDCredential.identityToken,
                  let tokenString = String(data: identityToken, encoding: .utf8) else {
                errorMessage = "Unable to fetch identity token"
                showError = true
                return
            }

            let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: tokenString, rawNonce: nil)

            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    errorMessage = "Firebase Apple Sign-In failed: \(error.localizedDescription)"
                    showError = true
                    return
                }

                guard let user = authResult?.user else {
                    errorMessage = "No Firebase user found"
                    showError = true
                    return
                }

                if let fullName = appleIDCredential.fullName {
                    username = "\(fullName.givenName ?? "") \(fullName.familyName ?? "")"
                } else {
                    username = "Apple User"
                }

                profileImage = "system:person.circle"

                saveUserToFirestore(uid: user.uid, username: username, profilePic: profileImage)
                saveJoinDate()
                UserDefaults.standard.set(true, forKey: "isLoggedIn")
                isLoggedIn = true
            }
        } else {
            errorMessage = "Apple credentials were not found."
            showError = true
        }
    }

    // MARK: - Google Sign-In
    private func googleSignIn() {
        #if canImport(UIKit)
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = scene.windows.first?.rootViewController else {
            errorMessage = "Could not find root view controller"
            showError = true
            return
        }

        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
            DispatchQueue.main.async {
                if let error = error {
                    errorMessage = "Google Sign-In failed: \(error.localizedDescription)"
                    showError = true
                } else if let user = result?.user {
                    handleGoogleSignIn(user: user)
                } else {
                    errorMessage = "Google Sign-In returned no user."
                    showError = true
                }
            }
        }
        #else
        errorMessage = "Google Sign-In is only supported on iOS."
        showError = true
        #endif
    }

    private func handleGoogleSignIn(user: GIDGoogleUser) {
        username = user.profile?.name ?? "No Name"
        if let profileURL = user.profile?.imageURL(withDimension: 100) {
            profileImage = profileURL.absoluteString
        }

        if let uid = Auth.auth().currentUser?.uid {
            saveUserToFirestore(uid: uid, username: username, profilePic: profileImage)
        }

        saveJoinDate()
        UserDefaults.standard.set(true, forKey: "isLoggedIn")
        isLoggedIn = true
    }

    // MARK: - Save User to Firestore
    private func saveUserToFirestore(uid: String, username: String, profilePic: String?) {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(uid)

        var data: [String: Any] = [
            "username": username,
            "joinDate": Timestamp(date: Date())
        ]

        if let profilePic = profilePic {
            data["profilePic"] = profilePic
        }

        userRef.setData(data, merge: true) { error in
            if let error = error {
                print("❌ Error saving user: \(error.localizedDescription)")
            } else {
                print("✅ User document saved successfully.")
            }
        }
    }

    // MARK: - Save Join Date (local)
    private func saveJoinDate() {
        if UserDefaults.standard.string(forKey: "joinDate") == nil {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            let joinDate = dateFormatter.string(from: Date())
            UserDefaults.standard.set(joinDate, forKey: "joinDate")
        }
    }
}
