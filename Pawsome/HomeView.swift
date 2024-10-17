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
                    loadPosts() // Load posts when the view appears
                }
                .sheet(isPresented: $showForm) {
                    if let selectedImage = selectedImage {
                        FormView(showForm: $showForm, navigateToHome: $navigateToHome, imageUI: selectedImage, username: currentUsername) { newPost in
                            catPosts.append(newPost)
                            savePosts() // Save posts when a new one is added
                        }
                    }
                }
                .onChange(of: navigateToHome) {
                    showForm = false
                    navigateToHome = false
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

                    // Like and Comment buttons
                    HStack {
                        // Like button
                        Button(action: {
                            if let index = catPosts.firstIndex(where: { $0.id == post.id }) {
                                if catPosts[index].likes > 0 { // Unlike
                                    catPosts[index].likes -= 1
                                } else { // Like
                                    catPosts[index].likes += 1
                                }
                                savePosts() // Save updated posts
                            }
                        }) {
                            HStack {
                                Image(systemName: catPosts.first(where: { $0.id == post.id })?.likes ?? 0 > 0 ? "hand.thumbsup.fill" : "hand.thumbsup")
                                Text("Like (\(post.likes))")
                            }
                        }
                        .buttonStyle(BorderlessButtonStyle())

                        Spacer()

                        // Comment button
                        Button(action: {
                            if let index = catPosts.firstIndex(where: { $0.id == post.id }) {
                                catPosts[index].showCommentInput.toggle()
                            }
                        }) {
                            HStack {
                                Image(systemName: "message")
                                Text("Comment")
                            }
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    .padding(.top, 5)

                    // Show comments
                    if post.comments.count > 0 {
                        ForEach(post.comments, id: \.self) { comment in
                            Text(comment)
                                .font(.subheadline)
                                .padding(.top, 2)
                        }
                    }

                    // Comment input field
                    if post.showCommentInput {
                        HStack {
                            TextField("Enter your comment", text: Binding(
                                get: {
                                    return ""
                                },
                                set: { newComment in
                                    if let index = catPosts.firstIndex(where: { $0.id == post.id }) {
                                        catPosts[index].comments.append(newComment)
                                        catPosts[index].showCommentInput = false
                                        savePosts() // Save updated posts with new comment
                                    }
                                }
                            ))
                            .textFieldStyle(RoundedBorderTextFieldStyle())

                            Button(action: {
                                if let index = catPosts.firstIndex(where: { $0.id == post.id }) {
                                    catPosts[index].showCommentInput = false
                                }
                            }) {
                                Text("Cancel")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
        }
    }

    // Load posts from storage (e.g., UserDefaults or a file)
    private func loadPosts() {
        if let data = UserDefaults.standard.data(forKey: "savedPosts"),
           let savedPosts = try? JSONDecoder().decode([CatPost].self, from: data) {
            catPosts = savedPosts
        }
    }

    // Save posts to storage
    private func savePosts() {
        if let data = try? JSONEncoder().encode(catPosts) {
            UserDefaults.standard.set(data, forKey: "savedPosts")
        }
    }
}
