import SwiftUI
import CoreData

struct HomeView: View {
    @Binding var isLoggedIn: Bool
    @Binding var currentUsername: String
    @Binding var profileImage: Image?

    @State private var catPosts: [CatPost] = []
    @State private var selectedImage: UIImage? = nil
    @State private var showForm: Bool = false
    @State private var navigateToHome: Bool = false
    @State private var isTabViewHidden: Bool = false // State to control TabView visibility

    // Core Data context
    @Environment(\.managedObjectContext) private var viewContext

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
                                    savePost(newPost) // Save the new post to Core Data
                                }
                            }
                        }
                        .onChange(of: navigateToHome) {
                            if $0 {
                                showForm = false // Dismiss the form
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
                                savePost(post) // Save the post to Core Data
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
            ForEach(catPosts, id: \.self) { post in
                LazyVStack(alignment: .leading) {
                    VStack(alignment: .leading) {
                        Text("Posted by: \(post.username ?? "")")
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

                        Text(post.name ?? "")
                            .font(.headline)
                        Text("Breed: \(post.breed ?? "")")
                        Text("Age: \(post.age ?? "")")
                        Text("Location: \(post.location ?? "")")
                        Text("Description: \(post.postDescription ?? "")")

                        HStack {
                            Button(action: {
                                // Toggle likes
                                let currentLikes = post.likes
                                post.likes = currentLikes > 0 ? 0 : 1 // Unlike or like
                                saveContext() // Save changes to Core Data
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

                            NavigationLink(destination: CommentsView(showComments: .constant(true), post: post)
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
        let request: NSFetchRequest<CatPost> = CatPost.fetchRequest()
        
        do {
            catPosts = try viewContext.fetch(request)
            print("Posts loaded from Core Data successfully")
        } catch {
            print("Error loading posts from Core Data: \(error)")
        }
    }

    private func savePost(_ post: CatPost) {
        // Create a new CatPost instance in Core Data
        let newPost = CatPost(context: viewContext)

        // Set creation and modification dates for the new post
        newPost.creationDate = Date()
        newPost.modificationDate = Date()

        // Use existing post properties for the new post
        newPost.imageData = post.imageData
        newPost.username = post.username
        newPost.likes = post.likes // Set likes as needed

        saveContext() // Save changes to Core Data
    }

    private func saveContext() {
        if viewContext.hasChanges {
            do {
                try viewContext.save()
                print("Posts saved to Core Data successfully")
            } catch {
                print("Error saving posts to Core Data: \(error)")
            }
        }
    }
}
