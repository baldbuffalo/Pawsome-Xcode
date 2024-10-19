import SwiftUI

struct HomeView: View {
    @Binding var isLoggedIn: Bool
    @Binding var currentUsername: String
    @Binding var profileImage: Image?

    @State private var catPosts: [CatPost] = []
    @State private var selectedImage: UIImage? = nil
    @State private var showForm: Bool = false
    @State private var navigateToHome: Bool = false
    @State private var selectedPost: CatPost? // Store the currently selected post for comments
    @State private var isTabViewHidden: Bool = false // State to control TabView visibility

    var body: some View {
        Group {
            if !isTabViewHidden {
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
                .navigationViewStyle(StackNavigationViewStyle())
            }
        }
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
            ForEach($catPosts) { $post in // Use a binding to access and update each post
                LazyVStack(alignment: .leading) {
                    VStack(alignment: .leading) {
                        // Show only the username
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
                                if post.likes > 0 {
                                    post.likes = 0 // Unlike
                                } else {
                                    post.likes = 1 // Like
                                }
                                savePosts()
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

                            // NavigationLink to CommentsView
                            NavigationLink(destination: CommentsView(showComments: Binding(
                                get: { true }, // Always show comments when navigating
                                set: { _ in } // Do nothing on set
                            ), post: Binding(
                                get: { post },
                                set: { newPost in
                                    if let index = catPosts.firstIndex(where: { $0.id == newPost.id }) {
                                        catPosts[index] = newPost // Update the post in catPosts
                                    }
                                }
                            )) // Pass post binding
                            .onAppear {
                                isTabViewHidden = true // Hide TabView when CommentsView appears
                            }
                            .onDisappear {
                                isTabViewHidden = false // Show TabView again when CommentsView disappears
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
