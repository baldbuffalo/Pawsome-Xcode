import SwiftUI
import FirebaseAuth
import FirebaseFirestore

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
                .bold()
                .padding()

            Text("Please sign in to continue")
                .font(.subheadline)
                .padding(.bottom, 50)

            Button(action: universalSignIn) {
                Text("Sign In")
                    .bold()
                    .frame(width: 280, height: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }

            Spacer()
        }
        .alert("Sign-In Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

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

            username = "User\(Int.random(in: 1000...9999))"
            profileImage = nil // default blank

            saveUserToFirestore(uid: user.uid)
        }
    }

    private func saveUserToFirestore(uid: String) {
        let userRef = Firestore.firestore().collection("users").document(uid)
        userRef.getDocument { snapshot, error in
            if let snapshot = snapshot, snapshot.exists {
                finishLogin()
            } else {
                userRef.setData([
                    "username": username,
                    "joinDate": Timestamp(date: Date())
                ]) { error in
                    if let error = error {
                        print("❌ Failed saving user: \(error.localizedDescription)")
                    } else {
                        print("✅ New user saved to Firestore.")
                    }
                    finishLogin()
                }
            }
        }
    }

    private func finishLogin() {
        UserDefaults.standard.set(username, forKey: "username")
        UserDefaults.standard.set(true, forKey: "isLoggedIn")
        isLoggedIn = true
    }

    private func showErrorWithMessage(_ msg: String) {
        errorMessage = msg
        showError = true
    }
}
