import SwiftUI
import CoreData

struct HomeView: View {
    @Binding var isLoggedIn: Bool
    @Binding var currentUsername: String
    @Binding var profileImage: Image?

    @State private var selectedImage: UIImage? = nil
    @State private var showForm: Bool = false
    @State private var navigateToHome: Bool = false
    @State private var isTabViewHidden: Bool = false

    @Environment(\.managedObjectContext) private var viewContext
    
    // Fetch CatPosts from Core Data sorted by timestamp
    @FetchRequest(
        entity: CatPost.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \CatPost.timestamp, ascending: false)] // Sort by timestamp
    ) var catPosts: FetchedResults<CatPost>

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
                        .sheet(isPresented: $showForm) {
                            if let selectedImage = selectedImage {
                                FormView(showForm: $showForm, navigateToHome: $navigateToHome, imageUI: selectedImage, videoURL: nil, username: currentUsername) { newPost in
                                    // Handle new post logic here
                                    savePost(from: newPost) // Pass the new post object
                                }
                            }
                        }
                        .onChange(of: navigateToHome) { newValue in
                            if newValue {
                                showForm = false
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
                                savePost(from: post) // Save the new post to Core Data
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

                    Text(post.catName ?? "")
                        .font(.headline)
                    Text("Breed: \(post.catBreed ?? "")")

                    let ageDisplay = post.catAge > 0 ? "\(post.catAge)" : "Unknown"
                    Text("Age: \(ageDisplay)")

                    Text("Location: \(post.location ?? "")")
                    Text("Description: \(post.postDescription ?? "")")

                    if let timestamp = post.timestamp {
                        Text("Posted on: \(formattedDate(timestamp))")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    }

                    HStack {
                        Button(action: {
                            post.likes = post.likes > 0 ? 0 : 1
                            saveContext()
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

                        // NavigationLink for comments
                        NavigationLink(destination: CommentsView(showComments: .constant(true), post: post)
                            .onAppear { isTabViewHidden = true }
                            .onDisappear { isTabViewHidden = false }) {
                            HStack {
                                Image(systemName: "message")
                                Text("Comment")
                            }
                        }
                        .buttonStyle(BorderlessButtonStyle())

                        // Show delete button only if the current user is the post owner
                        if post.username == currentUsername {
                            Button(action: {
                                deletePost(post: post) // Call delete function
                            }) {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("Delete")
                                }
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                    }
                    .padding(.top, 5)
                }
                .padding(.vertical)
            }
            .onDelete(perform: deletePosts) // Enable swipe to delete
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // Function to save a new CatPost
    private func savePost(from newPost: CatPost) {
        let catPost = CatPost(context: viewContext) // Create a new CatPost instance
        catPost.username = currentUsername // Set the username
        catPost.imageData = newPost.imageData // Set the imageData if available
        catPost.catName = newPost.catName // Set the catName
        catPost.catBreed = newPost.catBreed // Set the catBreed
        catPost.catAge = newPost.catAge // Updated property name to catAge
        catPost.location = newPost.location // Set the location
        catPost.postDescription = newPost.postDescription // Set the post description
        catPost.timestamp = Date() // Set the timestamp
        catPost.likes = 0 // Initialize likes to 0

        saveContext() // Save the context after creating the post
    }

    private func deletePost(post: CatPost) {
        viewContext.delete(post) // Delete the specified post
        saveContext() // Save the context after deletion
    }

    private func deletePosts(at offsets: IndexSet) {
        offsets.map { catPosts[$0] }.forEach(viewContext.delete) // Delete posts from offsets
        saveContext() // Save the context after deletion
    }

    private func saveContext() {
        if viewContext.hasChanges {
            do {
                try viewContext.save() // Save changes to Core Data
            } catch {
                print("Failed to save context: \(error)")
            }
        }
    }
}
