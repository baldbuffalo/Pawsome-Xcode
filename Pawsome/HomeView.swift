import SwiftUI

struct HomeView: View {
    @Binding var isLoggedIn: Bool // Binding to track login status
    @Binding var currentUsername: String // Binding to accept username
    @Binding var profileImage: Image? // Binding for the profile image

    @State private var catPosts: [CatPost] = [] // Array to hold cat posts
    @State private var selectedImage: UIImage? = nil
    @State private var showForm: Bool = false // State to control form visibility

    var body: some View {
        TabView {
            NavigationView {
                VStack(spacing: 0) {
                    headerView
                    postListView
                    Spacer() // Pushes the bottom bar to the bottom
                }
                .navigationTitle("Pawsome")
                .onAppear {
                    loadPosts() // Load posts when the view appears
                }
                .sheet(isPresented: $showForm) {
                    FormView(showForm: $showForm, imageUI: selectedImage) { newPost in
                        catPosts.append(newPost) // Add new post to the list
                        savePosts() // Save updated posts to UserDefaults
                    }
                }
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }

            NavigationView {
                ScanView(capturedImage: $selectedImage) {
                    showForm = true // Show form when an image is captured
                }
            }
            .tabItem {
                Label("Post", systemImage: "camera")
            }

            NavigationView {
                ProfileView(isLoggedIn: $isLoggedIn, currentUsername: currentUsername, profileImage: $profileImage)
                    .navigationTitle("Profile")
            }
            .tabItem {
                Label("Profile", systemImage: "person")
            }
        }
        .tabViewStyle(DefaultTabViewStyle())
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

    private func savePosts() {
        if let encoded = try? JSONEncoder().encode(catPosts) {
            UserDefaults.standard.set(encoded, forKey: "catPosts")
        }
    }
}
