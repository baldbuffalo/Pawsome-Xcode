import SwiftUI

struct HomeView: View {
    @Binding var isLoggedIn: Bool
    @Binding var currentUsername: String
    @Binding var profileImage: Image?

    @State private var catPosts: [CatPost] = []
    @State private var selectedImage: UIImage? = nil
    @State private var showForm: Bool = false
    @State private var navigateToHome: Bool = false
    @State private var showComments: Bool = false // State to control comment view visibility
    @State private var selectedPost: CatPost? = nil // Track which post's comments are shown

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
                    DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.1) {
                        loadPosts() // Load posts when the view appears, in background
                    }
                }
                .sheet(isPresented: $showForm) {
                    if let selectedImage = selectedImage {
                        FormView(showForm: $showForm, navigateToHome: $navigateToHome, imageUI: selectedImage, username: currentUsername) { newPost in
                            catPosts.append(newPost)
                            savePosts() // Save posts after adding a new one
                        }
                    }
                }
                .sheet(isPresented: $showComments) {
                    if let selectedPost = selectedPost {
                        // Create a Binding to the selectedPost
                        CommentsView(showComments: $showComments, post: Binding(
                            get: { selectedPost },
                            set: { newPost in
                                if let index = catPosts.firstIndex(where: { $0.id == newPost.id }) {
                                    catPosts[index] = newPost
                                }
                            }
                        ))
                    }
                }
                .onChange(of: navigateToHome) {
                    if navigateToHome {
                        showForm = false // Dismiss the form
                        navigateToHome = false // Reset the navigation state
                    }
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
                LazyVStack(alignment: .leading) {
                    VStack(alignment: .leading) {
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
                            Button(action: {
                                if let index = catPosts.firstIndex(where: { $0.id == post.id }) {
                                    DispatchQueue.main.async {
                                        catPosts[index].likes = catPosts[index].likes > 0 ? 0 : 1 // Toggle like status
                                    }
                                    savePosts()
                                }
                            }) {
                                HStack {
                                    Image(systemName: post.likes > 0 ? "hand.thumbsup.fill" : "hand.thumbsup")
                                    Text("Like (\(post.likes))")
                                }
                                .padding()
                                .background(Color.white.opacity(0.5))
                                .cornerRadius(8)
                            }
                            .buttonStyle(BorderlessButtonStyle())

                            Spacer()

                            // Comment button
                            Button(action: {
                                selectedPost = post
                                showComments = true // Show the comments view for this post
                            }) {
                                HStack {
                                    Image(systemName: "message")
                                    Text("Comment")
                                }
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                        .padding(.top, 5)
                    }
                    .padding(.vertical)
                }
            }
        }
    }

    private func loadPosts() {
        DispatchQueue.global(qos: .background).async {
            if let data = UserDefaults.standard.data(forKey: "catPosts") {
                if let decodedPosts = try? JSONDecoder().decode([CatPost].self, from: data) {
                    DispatchQueue.main.async {
                        catPosts = decodedPosts
                    }
                }
            }
        }
    }

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
