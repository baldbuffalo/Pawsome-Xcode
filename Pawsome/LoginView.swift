import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct LoginView: View {
    @Binding var isLoggedIn: Bool
    @Binding var username: String
    @Binding var profileImage: PlatformImage?

    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(spacing: 25) {
            Text("🐾 Welcome to Pawsome!")
                .font(.largeTitle)
                .bold()

            Text("Sign in to start finding cute cats 😻")
                .font(.subheadline)
                .padding(.bottom, 50)

            Button(action: {
                universalSignIn()
            }) {
                Text("Sign In")
                    .bold()
                    .frame(width: 280, height: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            Spacer()
        }
        .padding()
        .alert("Sign-In Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Universal Sign-In Handler
    private func universalSignIn() {
        Auth.auth().signInAnonymously { authResult, error in
            if let error = error {
                showErrorWithMessage("Login failed: \(error.localizedDescription)")
                return
            }

            guard let user = authResult?.user else {
                showErrorWithMessage("No user found after login.")
                return
            }

            let userRef = Firestore.firestore().collection("users").document(user.uid)
            userRef.getDocument { snapshot, error in
                if let snapshot = snapshot, snapshot.exists {
                    // ✅ Existing user — load data and skip Firestore write
                    if let data = snapshot.data(),
                       let savedUsername = data["username"] as? String {
                        username = savedUsername
                    }

                    if let imageURL = snapshot.data()?["profileImage"] as? String,
                       let url = URL(string: imageURL),
                       let imageData = try? Data(contentsOf: url),
                       let img = PlatformImage(data: imageData) {
                        profileImage = img
                    }

                    finishLogin()
                } else {
                    // 🆕 New user — generate username & set Firestore
                    username = "User\(Int.random(in: 1000...9999))"
                    profileImage = nil

                    let data: [String: Any] = [
                        "username": username,
                        "joinDate": Timestamp(date: Date()),
                        "profileImage": ""
                    ]

                    userRef.setData(data) { err in
                        if let err = err {
                            print("❌ Error saving user: \(err.localizedDescription)")
                        } else {
                            print("✅ New user saved.")
                        }
                        finishLogin()
                    }
                }
            }
        }
    }

    // MARK: - Complete Login
    private func finishLogin() {
        UserDefaults.standard.set(username, forKey: "username")
        UserDefaults.standard.set(true, forKey: "isLoggedIn")
        isLoggedIn = true
    }

    // MARK: - Error Helper
    private func showErrorWithMessage(_ msg: String) {
        errorMessage = msg
        showError = true
    }
}
