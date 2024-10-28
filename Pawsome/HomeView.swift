import SwiftUI
<<<<<<< HEAD

struct HomeView: View {
    @Binding var isLoggedIn: Bool
    @Binding var currentUsername: String
    @Binding var profileImage: Image?

    @State private var catPosts: [CatPost] = []
    @State private var selectedImage: UIImage? = nil
    @State private var showForm: Bool = false
    @State private var navigateToHome: Bool = false
    @State private var showComments: Bool = false
    @State private var selectedPost: CatPost? = nil

    var body: some View {
        TabView {
            NavigationStack {
                VStack(spacing: 0) {
                    headerView
                    postListView
                    Spacer()
                }
                .navigationTitle("Pawsome")
                .onAppear(perform: loadPosts)
                .sheet(isPresented: $showForm) {
                    if let selectedImage = selectedImage {
                        FormView(showForm: $showForm, navigateToHome: $navigateToHome, imageUI: selectedImage, username: currentUsername) { newPost in
                            catPosts.append(newPost)
                            savePosts()
                        }
                    }
                }
                .sheet(isPresented: $showComments) {
                    if let selectedPost = selectedPost {
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
                        savePosts()
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
                        
                        postActionButtons(for: post)
                    }
                    .padding(.vertical)
                }
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
        if let index = catPosts.firstIndex(where: { $0.id == post.id }) {
            DispatchQueue.main.async {
                catPosts[index].likes = catPosts[index].likes > 0 ? 0 : 1
            }
            savePosts()
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
=======
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showForm = false
    @State private var selectedImage: UIImage? = nil

    // Fetch existing CatPosts
    @FetchRequest(
        entity: CatPost.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \CatPost.timestamp, ascending: false)]
    ) private var posts: FetchedResults<CatPost>

    var body: some View {
        NavigationView {
            List(posts) { post in
                // Configure how each post is displayed
                Text(post.catName ?? "Unknown Cat")
            }
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showForm.toggle() }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showForm) {
                FormView(
                    showForm: $showForm,
                    currentUsername: "YourUsername",
                    onPostCreated: { newPost in
                        // Refresh or trigger any needed update in HomeView if necessary
                    },
                    selectedImage: $selectedImage
                )
                .environment(\.managedObjectContext, viewContext)
>>>>>>> 5eef0f8bd39986f9f45e071df446cc125709c1b6
            }
        }
    }
}
