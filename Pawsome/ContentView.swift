import SwiftUI

struct ContentView: View {
    @Binding var isLoggedIn: Bool  // Track login status
    
    var body: some View {
        VStack {
            if isLoggedIn {
                MainAppView()  // Show main content after login
            } else {
                LoginView(isLoggedIn: $isLoggedIn)  // Show login view
            }
        }
    }
}

struct MainAppView: View {
    @State private var selectedTab = 0  // Track the selected tab
    @State private var showProfileView = false  // Track profile view status
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()  // Home/Feed tab
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            UploadView()  // Upload tab
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text("Upload")
                }
                .tag(1)
            
            ProfileButtonView(showProfileView: $showProfileView)  // Profile tab
                .tabItem {
                    Image(systemName: "person.crop.circle.fill")
                    Text("Profile")
                }
                .tag(2)
        }
        .accentColor(.blue)  // Set accent color for TabView
        .sheet(isPresented: $showProfileView) {
            ProfileView(isLoggedIn: $showProfileView)  // This refers to your ProfileView in ProfileView.swift
        }
    }
}

// New struct for the Profile Button
struct ProfileButtonView: View {
    @Binding var showProfileView: Bool
    
    var body: some View {
        Button(action: {
            showProfileView = true  // Launch ProfileView when clicked
        }) {
            VStack {
                Image(systemName: "person.crop.circle.fill")
                Text("Profile")
            }
        }
    }
}

struct HomeView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Welcome to Pawsome!")
                    .font(.largeTitle)
                    .padding()
                
                Text("Explore the latest posts about adorable cats.")
                    .font(.subheadline)
                    .padding(.bottom, 20)
                
                // Placeholder for list of cat images/posts
                List(0..<10) { index in
                    HStack {
                        Image(systemName: "photo.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .cornerRadius(8)
                        
                        VStack(alignment: .leading) {
                            Text("Cat Post #\(index + 1)")
                                .font(.headline)
                            Text("User \(index + 1)")
                                .font(.subheadline)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Pawsome Feed")
        }
    }
}

struct UploadView: View {
    var body: some View {
        VStack {
            Text("Upload Your Cat Photo")
                .font(.title)
                .padding()
            
            Button(action: {
                // Action to upload a cat photo
                print("Upload button pressed")
            }) {
                Text("Upload Photo")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal, 20)
            }
            
            Spacer()
        }
    }
}
