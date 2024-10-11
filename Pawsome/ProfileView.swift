import SwiftUI

struct ProfileView: View {
    @Binding var isLoggedIn: Bool  // Logout binding
    var currentUsername: String      // User's username
    var profileImage: Image?         // Optional profile image

    var body: some View {
        VStack {
            Text("Your Profile")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()

            // Profile Picture
            if let profileImage = profileImage {
                profileImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle()) // Make the image circular
                    .padding(.top, 20)
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .padding(.top, 20)
            }

            Text(currentUsername.isEmpty ? "No Username" : currentUsername) // Display the current username
                .font(.headline)
                .padding(.top, 10)

            Divider()
                .padding(.vertical)

            // Profile Settings
            VStack(alignment: .leading, spacing: 15) {
                Text("Account Settings")
                    .font(.title2)
                    .fontWeight(.semibold)

                // Example of user settings options
                HStack {
                    Image(systemName: "envelope")
                    Text("Email: user@example.com") // Placeholder for email
                }

                HStack {
                    Image(systemName: "phone")
                    Text("Phone: +1234567890") // Placeholder for phone
                }

                HStack {
                    Image(systemName: "calendar")
                    Text("Joined: January 1, 2024") // Placeholder for join date
                }
            }
            .padding(.horizontal)

            Spacer()

            // Sign Out Button
            Button(action: {
                // Handle sign-out
                UserDefaults.standard.set(false, forKey: "isLoggedIn")
                isLoggedIn = false // Reset login state to show LoginView
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
        .padding()
        .navigationTitle("Profile Settings") // Optional: Add a navigation title
        .navigationBarTitleDisplayMode(.inline) // Optional: Adjust title display mode
    }
}
