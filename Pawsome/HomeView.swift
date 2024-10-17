import SwiftUI

struct HomeView: View {
    @Binding var isLoggedIn: Bool
    @Binding var currentUsername: String
    @Binding var profileImage: Image?

    @State private var catPosts: [CatPost] = []
    @State private var selectedImage: UIImage? = nil
    @State private var showForm: Bool = false
    @State private var navigateToHome: Bool = false // New state variable

    var body: some View {
        TabView {
            // Home Tab
            NavigationStack {
                VStack(spacing: 0) {
                    headerView
                    postListView
                    Spacer()
                }
                .navigationTitle("Pawsome")
                .onAppear {
                    loadPosts()
                }
                .sheet(isPresented: $showForm) {
                    if let selectedImage = selectedImage {
                        FormView(showForm: $showForm, navigateToHome: $navigateToHome, imageUI: selectedImage, username: currentUsername) { newPost in
                            catPosts.append(newPost)
                            savePosts()
                        }
                    }
                }
                .onChange(of: navigateToHome) {
                    // Handle navigation to HomeView
                    showForm = false // Dismiss the form
                    navigateToHome = false // Reset the navigation state
                }
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }
            
            // Post Tab
            NavigationStack {
                ScanView(
                    capturedImage: $selectedImage,
                    username: currentUsername,
                    onPostCreated: { post in
                        catPosts.append(post)
                        savePosts()
                    }
                )
                .onAppear {
                    // Additional logic if needed
                }
            }
            .tabItem {
                Label("Post", systemImage: "camera")
            }

            // Profile Tab
            NavigationStack {
                ProfileView(isLoggedIn: $isLoggedIn, currentUsername: $currentUsername, profileImage: $profileImage)
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
            Text("Hello, \(currentUsername)")
                .font(.subheadline)
                .padding(.bottom)
        }
    }

    private var postListView: some View {
        List {
            ForEach(catPosts) { post in
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
                    Text("Location: \(post.location)")
                    Text("Description: \(post.description)")
                    
                    // Like button
                    HStack {
                        Button(action: {
                            if let index = catPosts.firstIndex(where: { $0.id == post.id }) {
                                catPosts[index].likes += 1 // Increment likes
                                savePosts() // Save updated posts
                            }
                        }) {
                            HStack {
                                Image(systemName: "hand.thumbsup")
                                Text("Like (\(post.likes))") // Show current likes
                            }
                        }
                        .buttonStyle(BorderlessButtonStyle()) // To avoid row selection
                    }
                    .padding(.top, 5)
                }
                .padding(.vertical)
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
