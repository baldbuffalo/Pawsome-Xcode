import SwiftUI
import AVFoundation

struct ContentView: View {
    @Binding var isLoggedIn: Bool  // Track login status
    
    var body: some View {
        VStack(spacing: 0) {  // Set spacing to 0
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
    @State private var showScanView = false  // Track scan view status

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()  // Home/Feed tab
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            Button(action: {
                showScanView = true  // Show ScanView when button is pressed
            }) {
                VStack {
                    Image(systemName: "camera.fill")  // Icon for post
                    Text("Post")  // Button text
                }
            }
            .tabItem {
                Image(systemName: "camera.fill")
                Text("Post")  // Button text
            }
            .tag(1)
            .sheet(isPresented: $showScanView) {
                ScanView()  // Launch ScanView as a modal
            }
            
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
        VStack(spacing: 0) {  // Set spacing to 0 to remove extra gaps
            Text("Welcome to Pawsome!")
                .font(.largeTitle)
                .padding()
            
            Text("Explore the latest posts about adorable cats.")
                .font(.subheadline)
                .padding(.bottom, 20)
            
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
        // Removed NavigationView to eliminate the navigation bar
    }
}

// Preview for ContentView
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(isLoggedIn: .constant(true)) // Example of ContentView in previews
    }
}
