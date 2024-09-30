import SwiftUI
import AuthenticationServices
import GoogleSignIn

#if canImport(UIKit)
import UIKit
#endif

struct LoginView: View {
    @Binding var isLoggedIn: Bool

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
                    request.requestedScopes = [.fullName, .email] // Request full name and email
                },
                onCompletion: { result in
                    switch result {
                    case .success(let authResults):
                        // Handle successful Apple login
                        print("Apple sign-in success: \(authResults)")
                        UserDefaults.standard.set(true, forKey: "isLoggedIn") // Save login status
                        isLoggedIn = true // Update state to show ContentView
                    case .failure(let error):
                        // Handle error during sign-in
                        print("Apple sign-in failed: \(error.localizedDescription)")
                    }
                }
            )
            .signInWithAppleButtonStyle(.black)
            .frame(height: 50)
            .padding(.horizontal, 40)

            // Google Sign-In Button (iOS only)
            #if canImport(UIKit)
            Button(action: {
                // Trigger Google Sign-In
                guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let rootViewController = scene.windows.first?.rootViewController else {
                    print("Root view controller not found")
                    return
                }

                GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { user, error in
                    if let error = error {
                        print("Google Sign-In failed: \(error.localizedDescription)")
                    } else if let user = user {
                        // Handle successful Google login
                        print("Google Sign-In success: \(user)")
                        UserDefaults.standard.set(true, forKey: "isLoggedIn") // Save login status
                        isLoggedIn = true // Update state to show ContentView
                    }
                }
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
        }
    }
}
