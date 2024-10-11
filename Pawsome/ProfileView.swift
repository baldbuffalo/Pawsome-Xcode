import SwiftUI
import PhotosUI

struct ProfileView: View {
    @Binding var isLoggedIn: Bool  // Logout binding
    var currentUsername: String      // User's username
    @State private var profileImage: Image? = nil // Profile image as @State
    @State private var showImagePicker = false    // State to show image picker
    @State private var selectedItem: PhotosPickerItem? // State for selected item

    var body: some View {
        VStack {
            Text("Your Profile")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
            
            ZStack {
                // Profile Picture: Display the profile image from login or default placeholder
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
                        .clipShape(Circle()) // Circular default image
                        .padding(.top, 20)
                }
                
                // Pencil icon button
                Button(action: {
                    showImagePicker.toggle()
                }) {
                    Image(systemName: "pencil.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.blue)
                        .background(Color.white.opacity(0.7)) // Optional background
                        .clipShape(Circle())
                        .padding(5)
                }
                .offset(x: 40, y: -40) // Adjust position as needed
            }
            
            // Display the current username
            Text(currentUsername.isEmpty ? "No Username" : currentUsername)
                .font(.headline)
                .padding(.top, 10)
            
            Divider()
                .padding(.vertical)
            
            // Profile Settings
            VStack(alignment: .leading, spacing: 15) {
                Text("Account Settings")
                    .font(.title2)
                    .fontWeight(.semibold)
                
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
        .photosPicker(isPresented: $showImagePicker, selection: $selectedItem, matching: .images) // Image picker binding
        .onAppear {
            loadProfileImage() // Load profile image on appear
        }
        .onChange(of: selectedItem) {
            Task {
                if let newItem = selectedItem {
                    // Load the selected image asynchronously
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        profileImage = Image(uiImage: uiImage) // Set the new profile image
                        saveProfileImage(uiImage) // Save the new profile image
                    }
                }
            }
        }
    }

    // Function to load the profile image from UserDefaults
    private func loadProfileImage() {
        if let imageData = UserDefaults.standard.data(forKey: "profileImage") {
            if let uiImage = UIImage(data: imageData) {
                profileImage = Image(uiImage: uiImage) // Load the image
            }
        }
    }

    // Function to save the profile image to UserDefaults
    private func saveProfileImage(_ image: UIImage) {
        if let imageData = image.pngData() {
            UserDefaults.standard.set(imageData, forKey: "profileImage") // Save the image data
        }
    }
}
