import SwiftUI

struct LoginView: View {
    @Binding var isLoggedIn: Bool // Track login status
    @Binding var username: String  // Binding for username input
    @State private var usernameInput: String = "" // Temporary storage for username input
    @State private var passwordInput: String = "" // Temporary storage for password input

    var body: some View {
        VStack {
            Text("Login")
                .font(.largeTitle)
                .padding()

            TextField("Username", text: $usernameInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            SecureField("Password", text: $passwordInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button(action: {
                // Handle login logic (this is where you validate username/password)
                // If login is successful, set the username and isLoggedIn state
                username = usernameInput // Set the username for HomeView
                UserDefaults.standard.set(username, forKey: "username") // Save username
                isLoggedIn = true // Change login state
                UserDefaults.standard.set(true, forKey: "isLoggedIn") // Save login state persistently
            }) {
                Text("Log In")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()
        }
        .padding()
    }
}
