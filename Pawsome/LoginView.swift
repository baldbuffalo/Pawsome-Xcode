import SwiftUI
import AuthenticationServices
import GoogleSignIn
#if canImport(UIKit)
import UIKit
#endif

struct LoginView: View {
    @Binding var isLoggedIn: Bool
    @Binding var username: String
    @Binding var profileImage: Image?

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
    }

    private func handleAppleSignIn(result: ASAuthorization) {
        if let appleIDCredential = result.credential as? ASAuthorizationAppleIDCredential {
            if let fullName = appleIDCredential.fullName {
                username = "\(fullName.givenName ?? "") \(fullName.familyName ?? "")"
                print("Signed in with Apple: \(username)")
            }
            profileImage = Image(systemName: "person.circle")
            saveJoinDate()
            UserDefaults.standard.set(true, forKey: "isLoggedIn")
            isLoggedIn = true
        }
    }

    private func googleSignIn() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = scene.windows.first?.rootViewController else {
            print("Root view controller not found")
            return
        }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Google Sign-In failed: \(error.localizedDescription)")
                } else if let user = result?.user {
                    handleGoogleSignIn(user: user)
                }
            }
        }
    }

    private func handleGoogleSignIn(user: GIDGoogleUser) {
        username = user.profile?.name ?? ""
        if let profileURL = user.profile?.imageURL(withDimension: 100) {
            loadImage(from: profileURL) { image in
                profileImage = image
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

// Function to load the profile image asynchronously
func loadImage(from url: URL, completion: @escaping (Image?) -> Void) {
    let task = URLSession.shared.dataTask(with: url) { data, _, error in
        if error != nil || data == nil {
            DispatchQueue.main.async { completion(nil) }
            return
        }
        DispatchQueue.main.async {
            completion(data.flatMap { Image(uiImage: UIImage(data: $0)!) })
        }
    }
    task.resume()
}
