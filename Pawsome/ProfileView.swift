import SwiftUI
import PhotosUI

struct ProfileView: View {
    @Binding var isLoggedIn: Bool  // Logout binding
    @Binding var currentUsername: String // Make currentUsername a Binding
    @Binding var profileImage: Image? // Profile image as a binding
    @State private var showImagePicker = false    // State to show image picker
    @State private var selectedItem: PhotosPickerItem? // State for selected item
    @FocusState private var isUsernameFocused: Bool // State to track focus on the username TextField
    @State private var joinDate: String = "" // State to hold join date
<<<<<<< HEAD

    var body: some View {
        VStack {
            Text("Your Profile")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
            
=======
    @State private var isEditing: Bool = false // State to manage edit mode

    var body: some View {
        VStack {
            // Header with Edit button and pencil icon
            HStack {
                Text("Your Profile")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                
                Spacer() // Pushes the edit button to the right
                
                // Edit/Save Button
                Button(action: {
                    if isEditing {
                        // Save changes when in editing mode
                        // Add your save logic here if necessary
                    }
                    isEditing.toggle() // Toggle edit mode
                }) {
                    Text(isEditing ? "Save" : "Edit") // Change button title based on editing state
                        .font(.headline)
                        .foregroundColor(.blue) // Change text color to blue
                        .padding(.vertical, 10) // Adjust vertical padding
                        .padding(.horizontal, 20) // Adjust horizontal padding for spacing
                }
                .buttonStyle(PlainButtonStyle()) // Remove background and border
            }
            .padding(.top)

>>>>>>> 5eef0f8bd39986f9f45e071df446cc125709c1b6
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
                
<<<<<<< HEAD
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
=======
                // Pencil icon button (shown only in edit mode)
                if isEditing {
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
>>>>>>> 5eef0f8bd39986f9f45e071df446cc125709c1b6
            }
            
            // Editable username field
            TextField("Username", text: $currentUsername) // TextField for username
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .padding(.top, 10)
                .focused($isUsernameFocused) // Bind focus state to the TextField
            
            // Display the current username if not focused
            if !isUsernameFocused {
                Text(currentUsername.isEmpty ? "No Username" : currentUsername)
                    .font(.headline)
                    .padding(.top, 10)
            }
            
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
                    Text("Joined: \(joinDate)") // Display the join date
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
            loadUsername() // Load username on appear
            loadJoinDate() // Load join date on appear
        }
<<<<<<< HEAD
        .onChange(of: currentUsername) { newValue in
=======
        .onChange(of: currentUsername) { oldValue, newValue in
>>>>>>> 5eef0f8bd39986f9f45e071df446cc125709c1b6
            // Save the updated username to UserDefaults
            UserDefaults.standard.set(newValue, forKey: "currentUsername")
        }
        .contentShape(Rectangle()) // Allows the entire VStack to be tappable
        .onTapGesture {
            isUsernameFocused = false // Dismiss keyboard when tapping outside
        }
<<<<<<< HEAD
        .onChange(of: selectedItem) { newItem in
=======
        .onChange(of: selectedItem) { oldItem, newItem in
>>>>>>> 5eef0f8bd39986f9f45e071df446cc125709c1b6
            if let newItem = newItem {
                Task {
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
    
    // Function to load the username from UserDefaults
    private func loadUsername() {
        if let savedUsername = UserDefaults.standard.string(forKey: "currentUsername") {
            currentUsername = savedUsername // Load the saved username
        }
    }

    // Function to load the join date from UserDefaults
    private func loadJoinDate() {
        if let savedJoinDate = UserDefaults.standard.string(forKey: "joinDate") {
            joinDate = savedJoinDate // Load the saved join date
        } else {
            joinDate = "Not available" // Default if not found
        }
    }

    // Function to save the profile image to UserDefaults
    private func saveProfileImage(_ image: UIImage) {
        if let imageData = image.pngData() {
            UserDefaults.standard.set(imageData, forKey: "profileImage") // Save the image data
        }
    }
}
