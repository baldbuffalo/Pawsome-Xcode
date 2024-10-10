import SwiftUI

struct HomeView: View {
    @Binding var isLoggedIn: Bool
    @State private var showScanView = false
    @State private var capturedImage: UIImage? = nil
    @State private var selectedTab = 0
    @State private var currentUsername = "User" // Placeholder for username

    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            NavigationView {
                VStack(spacing: 0) {
                    headerView
                    // Post List view has been removed
                }
                .navigationTitle("Pawsome") // Set navigation title if needed
            }
            .tabItem {
                Image(systemName: "house.fill")
                Text("Home")
            }
            .tag(0)

            // Post Tab (Scan View)
            Button(action: {
                showScanView.toggle() // Show the scan view
            }) {
                VStack {
                    Text("Create New Post")
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(10)
                        .foregroundColor(.white)
                }
            }
            .tabItem {
                Image(systemName: "plus.circle.fill")
                Text("Post")
            }
            .tag(1)
            .sheet(isPresented: $showScanView) {
                ScanView(capturedImage: $capturedImage, currentUsername: currentUsername)
            }

            // Profile Tab
            profileView
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(2)
        }
        .onChange(of: capturedImage) { newImage in
            handleNewImage(newImage)
        }
    }

    // Header View
    private var headerView: some View {
        VStack(spacing: 0) {
            Text("Welcome to Pawsome!")
                .font(.largeTitle)
                .padding()

            Text("Explore the latest posts about adorable cats.")
                .font(.subheadline)
                .padding(.bottom, 20)
        }
    }

    // Profile View
    private var profileView: some View {
        VStack {
            Text("User Profile")
                .font(.largeTitle)
                .padding()

            Button(action: {
                isLoggedIn = false // Log out action
            }) {
                Text("Log Out")
                    .padding()
                    .background(Color.red)
                    .cornerRadius(10)
                    .foregroundColor(.white)
            }
            .padding()
        }
    }

    // Handle new captured image
    private func handleNewImage(_ newImage: UIImage?) {
        guard let image = newImage else { return }
        
        // Here you can handle the new image without creating a CatPost
        // For example, you might display it or save it elsewhere
        capturedImage = nil // Reset captured image
    }
}
