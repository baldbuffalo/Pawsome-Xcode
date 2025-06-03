import SwiftUI
import AuthenticationServices
import GoogleSignIn

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

            // Apple Sign-In Button
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

            // Google Sign-In Button (iOS only)
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

    private func handleAppleSignIn(result: ASAuthorization) {
        if let appleIDCredential = result.credential as? ASAuthorizationAppleIDCredential {
            if let fullName = appleIDCredential.fullName {
                username = "\(fullName.givenName ?? "") \(fullName.familyName ?? "")"
                print("Signed in with Apple: \(username)")
            }
            profileImage = "system:person.circle" // Use your logic for profile image
            saveJoinDate()
            UserDefaults.standard.set(true, forKey: "isLoggedIn")
            isLoggedIn = true
        } else {
            errorMessage = "Apple credentials were not found."
            showError = true
        }
    }

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
            loadImage(from: profileURL) { result in
                profileImage = profileURL.absoluteString
            }
        }
        saveJoinDate()
        UserDefaults.standard.set(true, forKey: "isLoggedIn")
        isLoggedIn = true
    }

    private func saveJoinDate() {
        if UserDefaults.standard.string(forKey: "joinDate") == nil {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            let joinDate = dateFormatter.string(from: Date())
            UserDefaults.standard.set(joinDate, forKey: "joinDate")
        }
    }
}

func loadImage(from url: URL, completion: @escaping (String) -> Void) {
    URLSession.shared.dataTask(with: url) { data, _, _ in
        DispatchQueue.main.async {
            completion(url.absoluteString)
        }
    }.resume()
}
