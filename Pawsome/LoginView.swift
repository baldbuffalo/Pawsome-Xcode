import SwiftUI
import AuthenticationServices
import GoogleSignIn
#if canImport(UIKit)
import UIKit
#endif

struct LoginView: View {
    @Binding var isLoggedIn: Bool
    @Binding var username: String // Add binding for the username
    @Binding var profileImage: Image? // Add binding for the profile image

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
                        if let appleIDCredential = authResults.credential as? ASAuthorizationAppleIDCredential {
                            // Safely unwrap fullName
                            if let fullName = appleIDCredential.fullName {
                                // Concatenate first and last name
                                username = "\(fullName.givenName ?? "") \(fullName.familyName ?? "")"
                            }
                            // Apple does not provide a profile image URL, so we'll leave it as nil or set a default
                            profileImage = nil // Set a default image if needed
                        }
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
                
                GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
                    if let error = error {
                        print("Google Sign-In failed: \(error.localizedDescription)")
                    } else if let user = result?.user {
                        username = user.profile?.name ?? "" // Set the username
                        if let profileURL = user.profile?.imageURL(withDimension: 100) {
                            // Load the image from the URL
                            loadImage(from: profileURL) { image in
                                profileImage = image // Set the loaded profile image
                            }
                        } else {
                            profileImage = nil // Handle the case where there is no image
                        }
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

// Function to load the image asynchronously
func loadImage(from url: URL, completion: @escaping (Image?) -> Void) {
    let task = URLSession.shared.dataTask(with: url) { data, response, error in
        guard let data = data, error == nil else {
            DispatchQueue.main.async {
                completion(nil)
            }
            return
        }
        
        if let uiImage = UIImage(data: data) {
            let image = Image(uiImage: uiImage)
            DispatchQueue.main.async {
                completion(image)
            }
        } else {
            DispatchQueue.main.async {
                completion(nil)
            }
        }
    }
    task.resume()
}
