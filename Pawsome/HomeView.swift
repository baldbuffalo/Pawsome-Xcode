import SwiftUI

struct HomeView: View {
    @Binding var isLoggedIn: Bool // Binding to track login status
    @Binding var currentUsername: String // Binding to accept username
    @Binding var profileImage: Image? // Binding for the profile image

    @State private var catPosts: [CatPost] = [] // Array to hold cat posts
    @State private var showForm: Bool = false
    @State private var selectedImage: UIImage? = nil
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

            // Directly navigate to ScanView when the Post tab is clicked
            NavigationView {
                ScanView(capturedImage: .constant(nil), hideTabBar: $hideTabBar) // Use binding for hideTabBar
            }
            .tabItem {
                Label("Post", systemImage: "camera")
            }

            NavigationView {
                // Pass the profileImage binding to ProfileView
                ProfileView(isLoggedIn: $isLoggedIn, currentUsername: currentUsername, profileImage: $profileImage)
                    .navigationTitle("Profile")
            }
            .tabItem {
                Label("Profile", systemImage: "person")
            }
        }
        .tabViewStyle(DefaultTabViewStyle())
        .edgesIgnoringSafeArea(hideTabBar ? .bottom : [])
        .animation(.easeInOut, value: hideTabBar) // Smooth transition
        .onAppear {
            // Reset the hideTabBar when the view appears
            hideTabBar = false
        }
    }

    private var headerView: some View {
        VStack {
            Text("Welcome to Pawsome")
                .font(.largeTitle)
                .padding()
            Text("Hello, \(currentUsername)") // Displaying the username
                .font(.subheadline)
                .padding(.bottom)
        }
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
