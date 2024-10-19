import SwiftUI

struct HomeView: View {
    @Binding var isLoggedIn: Bool
    @Binding var currentUsername: String
    @Binding var profileImage: Image?

    @State private var catPosts: [CatPost] = []
    @State private var selectedImage: UIImage? = nil
    @State private var showForm: Bool = false
    @State private var navigateToHome: Bool = false

    var body: some View {
        NavigationStack {
            TabView {
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

                // Ensure this destination is declared before the NavigationLink
                .navigationDestination(for: CatPost.self) { post in
                    CommentsView(showComments: .constant(true), post: Binding(
                        get: { post },
                        set: { newPost in
                            if let index = catPosts.firstIndex(where: { $0.id == newPost.id }) {
                                catPosts[index] = newPost // Update the post in catPosts
                            }
                        }
                    ))
                }

                .tabItem {
                    Label("Home", systemImage: "house")
                }

                // Other tab views...
            }
        }
        .navigationViewStyle(StackNavigationViewStyle()) // Optional, depending on your UI
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
            ForEach($catPosts) { $post in
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
                            NavigationLink(value: post) {
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
