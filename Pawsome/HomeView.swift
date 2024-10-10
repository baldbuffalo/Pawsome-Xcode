import SwiftUI

struct HomeView: View {
    @Binding var isLoggedIn: Bool // Binding to track login status
    @State private var currentUsername: String = "User" // Replace with actual logic to get the username
    @State private var catPosts: [CatPost] = [] // Array to hold cat posts
    @State private var showForm: Bool = false
    @State private var selectedImage: UIImage? = nil
    @State private var capturedImage: UIImage? = nil // Manage captured images
    @State private var hideTabBar: Bool = false // Control tab bar visibility

    var body: some View {
        TabView {
            NavigationView {
                VStack(spacing: 0) {
                    headerView
                    postListView
                    Spacer() // Pushes the bottom bar to the bottom
                }
                .navigationTitle("Pawsome")
                .sheet(isPresented: $showForm) {
                    // Present the form with bindings
                    FormView(showForm: $showForm, catPosts: $catPosts, imageUI: selectedImage)
                }
                .onAppear {
                    loadPosts() // Load posts when the view appears
                }
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }
            
            NavigationView {
                // Use ScanView and pass the new hideTabBar binding
                ScanView(capturedImage: $capturedImage, hideTabBar: $hideTabBar) // Pass the required parameters
            }
            .tabItem {
                Label("Post", systemImage: "camera")
            }
            
            NavigationView {
                ProfileView(isLoggedIn: $isLoggedIn, currentUsername: currentUsername) // Pass the required parameters
                    .navigationTitle("Profile")
            }
            .tabItem {
                Label("Profile", systemImage: "person")
            }
        }
        .tabViewStyle(DefaultTabViewStyle())
        .edgesIgnoringSafeArea(hideTabBar ? .bottom : [])
        .animation(hideTabBar ? .easeInOut : .default, value: hideTabBar) // Updated animation syntax
    }

    private var headerView: some View {
        // Your header view implementation here
        Text("Welcome to Pawsome")
            .font(.largeTitle)
            .padding()
    }

    private var postListView: some View {
        List(catPosts) { post in
            // Your post view implementation here
            VStack(alignment: .leading) {
                if let imageData = post.imageData, let image = UIImage(data: imageData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .cornerRadius(12)
                }
                Text(post.name)
                    .font(.headline)
                Text("Breed: \(post.breed)")
                Text("Age: \(post.age)")
                Text("Posted by: \(post.username)")
                Text("Comments: \(post.comments.joined(separator: ", "))")
            }
        }
    }

    private func loadPosts() {
        if let data = UserDefaults.standard.data(forKey: "catPosts"),
           let decodedPosts = try? JSONDecoder().decode([CatPost].self, from: data) {
            catPosts = decodedPosts
        }
    }
}
