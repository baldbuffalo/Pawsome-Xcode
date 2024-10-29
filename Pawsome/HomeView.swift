import SwiftUI
import CoreData

struct HomeView: View {
    @Binding var isLoggedIn: Bool
    @Binding var currentUsername: String
    @Binding var profileImage: Image?

    @State private var showForm: Bool = false
    @State private var selectedImage: UIImage? = nil
    @State private var navigateToHome: Bool = false
    @State private var showComments: Bool = false
    @State private var selectedPost: CatPost? = nil

    // Fetch existing CatPosts from Core Data
    @FetchRequest(
        entity: CatPost.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \CatPost.timestamp, ascending: false)]
    ) private var posts: FetchedResults<CatPost>

    var body: some View {
        TabView {
            NavigationStack {
                VStack(spacing: 0) {
                    headerView
                    postListView
                    Spacer()
                }
                .navigationTitle("Pawsome")
                .sheet(isPresented: $showForm) {
                    FormView(
                        showForm: $showForm,
                        navigateToHome: $navigateToHome,
                        imageUI: selectedImage,
                        username: currentUsername
                    ) { newPost in
                        savePost(newPost) // Save the new post
                    }
                }
                .sheet(isPresented: $showComments) {
                    if let selectedPost = selectedPost {
                        CommentsView(showComments: $showComments, post: Binding(
                            get: { selectedPost },
                            set: { newPost in
                                updatePost(newPost) // Update the post when comments are changed
                            }
                        ))
                    }
                }
                .onChange(of: navigateToHome) {
                    if $0 {
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
                        savePost(post) // Save the post created in ScanView
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

            // Display the profile image if available
            if let profileImage = profileImage {
                profileImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                    .padding(.bottom)
            }
        }
    }

    private var postListView: some View {
        List(posts, id: \.self) { post in
            LazyVStack(alignment: .leading) {
                VStack(alignment: .leading) {
                    Text("Posted by: \(post.username ?? "Unknown")")
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

                    Text(post.name ?? "Unknown")
                        .font(.headline)
                    Text("Breed: \(post.breed ?? "N/A")")
                    Text("Age: \(post.age ?? "N/A")")
                    Text("Location: \(post.location ?? "N/A")")
                    Text("Description: \(post.description ?? "N/A")")
                    
                    postActionButtons(for: post)
                }
                .padding(.vertical)
            }
        }
    }

    private func postActionButtons(for post: CatPost) -> some View {
        HStack {
            Button(action: {
                toggleLike(for: post)
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

            Button(action: {
                selectedPost = post
                showComments = true
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

    private func toggleLike(for post: CatPost) {
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            DispatchQueue.main.async {
                posts[index].likes = posts[index].likes > 0 ? 0 : 1
            }
            savePosts() // Save changes after toggling like
        }
    }

    private func savePost(_ post: CatPost) {
        let newPost = CatPost(context: viewContext) // Create a new CatPost in Core Data
        newPost.username = currentUsername
        newPost.imageData = post.imageData // Assuming you're passing the image data
        newPost.name = post.name
        newPost.breed = post.breed
        newPost.age = post.age
        newPost.location = post.location
        newPost.description = post.description
        newPost.timestamp = Date()

        savePosts() // Save the context to persist the new post
    }

    private func updatePost(_ post: CatPost) {
        // Implement logic to update the post in Core Data if needed
        savePosts() // Call save to persist updates
    }

    private func savePosts() {
        do {
            try viewContext.save() // Save the context to persist changes
            print("Posts saved successfully")
        } catch {
            print("Error saving posts: \(error.localizedDescription)")
        }
    }
}
