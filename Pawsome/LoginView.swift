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
                    request.requestedScopes = [.fullName, .email]
                },
                onCompletion: { result in
                    switch result {
                    case .success(let authResults):
                        if let appleIDCredential = authResults.credential as? ASAuthorizationAppleIDCredential {
                            if let fullName = appleIDCredential.fullName {
                                // Set the username
                                username = "\(fullName.givenName ?? "") \(fullName.familyName ?? "")"
                                print("Signed in with Apple: \(username)") // Debug output
                            }
                            // No profile image is provided by Apple, so set to nil or a default
                            profileImage = nil // You might consider setting a default image here
                        }
                        UserDefaults.standard.set(true, forKey: "isLoggedIn")
                        isLoggedIn = true // Mark as logged in
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
                guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let rootViewController = scene.windows.first?.rootViewController else {
                    print("Root view controller not found")
                    return
                }
                
                GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
                    if let error = error {
                        print("Google Sign-In failed: \(error.localizedDescription)")
                    } else if let user = result?.user {
                        // Set the username from Google
                        username = user.profile?.name ?? ""
                        print("Signed in with Google: \(username)") // Debug output
                        
                        if let profileURL = user.profile?.imageURL(withDimension: 100) {
                            // Load the profile image
                            loadImage(from: profileURL) { image in
                                profileImage = image // Pass the image to the ProfileView later
                            }
                        } else {
                            profileImage = nil // Handle no profile image
                            print("No profile image URL available from Google.")
                        }
                        
                        UserDefaults.standard.set(true, forKey: "isLoggedIn")
                        isLoggedIn = true // Mark as logged in
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
            
            // Navigate to ProfileView if logged in
            if isLoggedIn {
                NavigationLink(destination: ProfileView(isLoggedIn: $isLoggedIn, currentUsername: username, profileImage: $profileImage)) {
                    Text("Go to Profile")
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                        .padding()
                }
            }
        }
    }
}

// Function to load the profile image asynchronously
func loadImage(from url: URL, completion: @escaping (Image?) -> Void) {
    let task = URLSession.shared.dataTask(with: url) { data, response, error in
        if let error = error {
            print("Error fetching image: \(error.localizedDescription)")
            DispatchQueue.main.async {
                completion(nil)
            }
            return
        }
        
        if let httpResponse = response as? HTTPURLResponse {
            print("HTTP Response Status Code: \(httpResponse.statusCode)")
        }

        guard let data = data, !data.isEmpty else {
            print("No data or empty response received.")
            DispatchQueue.main.async {
                completion(nil)
            }
            return
        }

        if let uiImage = UIImage(data: data) {
            DispatchQueue.main.async {
                completion(Image(uiImage: uiImage))
            }
        } else {
            print("Failed to create image from data.")
            DispatchQueue.main.async {
                completion(nil)
            }
        }
    }
    task.resume()
}
