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
                                    savePostsToFile() // Save posts after adding a new one
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
                                savePostsToFile() // Save posts after creating a new post
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
                                savePostsToFile() // Save changes
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
                            NavigationLink(destination: CommentsView(showComments: .constant(true), post: Binding(
                                get: { post },
                                set: { newPost in
                                    if let index = catPosts.firstIndex(where: { $0.id == newPost.id }) {
                                        catPosts[index] = newPost // Update the post in catPosts
                                    }
                                }
                            ))
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
        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("catPosts.json")
        
        do {
            let data = try Data(contentsOf: fileURL)
            catPosts = try JSONDecoder().decode([CatPost].self, from: data)
            print("Posts loaded from file successfully")
        } catch {
            print("Error loading posts from file: \(error)")
        }
    }

    private func savePostsToFile() {
        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("catPosts.json")
        
        do {
            let data = try JSONEncoder().encode(catPosts)
            try data.write(to: fileURL)
            print("Posts saved to file successfully")
        } catch {
            print("Error saving posts to file: \(error)")
        }
    }
}
