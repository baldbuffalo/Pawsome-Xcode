import SwiftUI

struct HomeView: View {
    @Binding var isLoggedIn: Bool // Binding to track login status
    @State private var currentUsername: String = "User" // Replace with actual logic to get the username
    @State private var catPosts: [CatPost] = [] // Array to hold cat posts
    @State private var showForm: Bool = false
    @State private var selectedImage: UIImage? = nil
    @State private var capturedImage: UIImage? = nil // Manage captured images
    @State private var hideTabBar: Bool = false // Control tab bar visibility
    @State private var showScanView: Bool = false // Control ScanView visibility

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
            
            NavigationStack {
                VStack {
                    Button("Start Scan") {
                        showScanView = true // Activate the NavigationLink
                    }
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)

                    // NavigationLink to open ScanView using the new method
                    NavigationLink(value: "ScanView") {
                        EmptyView() // Invisible part of the NavigationLink
                    }
                    .navigationDestination(for: String.self) { value in
                        if value == "ScanView" {
                            ScanView(capturedImage: $capturedImage, hideTabBar: $hideTabBar)
                        }
                    }
                }
                .navigationTitle("Scan") // Optional title for the Scan view
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
        Text("Welcome to Pawsome")
            .font(.largeTitle)
            .padding()
    }

    private var postListView: some View {
        List(catPosts) { post in
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
