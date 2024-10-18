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
            NavigationStack {
                VStack(spacing: 0) {
                    headerView
                    postListView
                    Spacer()
                }
                .navigationTitle("Pawsome")
                .onAppear {
                    loadPosts() // Load posts when the view appears
                }
                .sheet(isPresented: $showForm) {
                    if let selectedImage = selectedImage {
                        FormView(showForm: $showForm, navigateToHome: $navigateToHome, imageUI: selectedImage, username: currentUsername) { newPost in
                            catPosts.append(newPost)
                            savePosts() // Save posts after adding a new one
                        }
                    }
                }
                .onChange(of: navigateToHome) {
                    showForm = false // Dismiss the form
                    navigateToHome = false // Reset the navigation state
                }
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }

            NavigationStack {
                ScanView(
                    capturedImage: $selectedImage,
                    username: currentUsername,
                    onPostCreated: { post in
                        catPosts.append(post)
                        savePosts() // Save posts after creating a new post
                    }
                )
                .onAppear {
                    // Additional logic if needed
                }
            }
            .tabItem {
                Label("Post", systemImage: "camera")
            }

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
                    // Display the name of the person who posted
                    Text("Posted by: \(post.username)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.bottom, 2)

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
                    
                    HStack {
                        // Like button
                        Button(action: {
                            if let index = catPosts.firstIndex(where: { $0.id == post.id }) {
                                // Update UI on the main thread
                                DispatchQueue.main.async {
                                    catPosts[index].likes = catPosts[index].likes > 0 ? 0 : 1 // Toggle like status
                                }
                                // Save posts in the background
                                savePosts()
                            }
                        }) {
                            HStack {
                                Image(systemName: post.likes > 0 ? "hand.thumbsup.fill" : "hand.thumbsup")
                                Text("Like (\(post.likes))") // Show current likes
                            }
                            .padding()
                            .background(Color.white.opacity(0.5)) // Optional: background for the button
                            .cornerRadius(8) // Optional: corner radius for button
                        }
                        .buttonStyle(BorderlessButtonStyle()) // To avoid row selection

                        Spacer() // Add space between buttons

                        // Comment button
                        Button(action: {
                            print("Comment button tapped for post: \(post.id)")
                        }) {
                            HStack {
                                Image(systemName: "message")
                                Text("Comment") // Show comment button
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

    // Function to load posts from UserDefaults
    private func loadPosts() {
        if let data = UserDefaults.standard.data(forKey: "catPosts") {
            if let decodedPosts = try? JSONDecoder().decode([CatPost].self, from: data) {
                catPosts = decodedPosts // Load saved posts
            }
        }
    }

    // Function to save posts to UserDefaults
    private func savePosts() {
        DispatchQueue.global(qos: .background).async {
            if let encodedPosts = try? JSONEncoder().encode(catPosts) {
                UserDefaults.standard.set(encodedPosts, forKey: "catPosts")
                DispatchQueue.main.async {
                    print("Posts saved successfully")
                }
            }
        }
    }
}
