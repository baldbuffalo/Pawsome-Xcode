import SwiftUI

struct ProfileView: View {
    @Binding var isLoggedIn: Bool  // Logout binding

    var body: some View {
        VStack {
            Text("Your Profile")
                .font(.largeTitle)
                .padding()
            
            // Placeholder for user information
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .frame(width: 100, height: 100)
                .padding(.top, 20)
            
            Text("User Name")
                .font(.headline)
                .padding(.top, 10)
            
            Button(action: {
                // Handle sign-out
                UserDefaults.standard.set(false, forKey: "isLoggedIn")
                isLoggedIn = false  // Reset login state to show LoginView
            }) {
                Text("Sign Out")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal, 20)
            }
        }
    }
}
