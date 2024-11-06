import SwiftUI
import Firebase
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

    // Environment context for Core Data
    @Environment(\.managedObjectContext) private var viewContext

    // Fetch existing CatPosts from Core Data
    @FetchRequest(
        entity: CatPost.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \CatPost.timestamp, ascending: false)]
    ) private var posts: FetchedResults<CatPost>

    var body: some View {
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
                    username: currentUsername,
                    dataManager: DataManager(context: viewContext) // Initialize DataManager here
                )
            }
            .sheet(isPresented: $showComments) {
                if let selectedPost = selectedPost {
                    CommentsView(showComments: $showComments, post: selectedPost) // Pass CatPost directly
                }
            }
            .onChange(of: navigateToHome) {
                if $0 {
                    showForm = false // Dismiss the form
                    navigateToHome = false // Reset the navigation state
                }
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

                    Text(post.catName ?? "Unknown")
                        .font(.headline)
                    Text("Breed: \(post.catBreed ?? "N/A")")
                    Text("Age: \(post.catAge)") // Directly display Int32 catAge
                    Text("Location: \(post.location ?? "N/A")")
                    Text("Description: \(post.postDescription ?? "N/A")")

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
        post.likes = post.likes > 0 ? 0 : 1
        savePosts() // Save changes after toggling like
    }

    private func savePost(
        catName: String,
        catBreed: String,
        catAge: Int32,
        location: String,
        postDescription: String,
        postImage: UIImage // Assuming you're getting the post image from the form
    ) {
        // Create a new CatPost in Core Data
        let newPost = CatPost(context: viewContext)
        newPost.username = currentUsername
        newPost.imageData = postImage.pngData() // Save the post image as data
        newPost.catName = catName
        newPost.catBreed = catBreed
        newPost.catAge = catAge
        newPost.location = location
        newPost.postDescription = postDescription
        newPost.timestamp = Date()

        // Upload the post to Firebase
        uploadCatPostToFirebase(post: newPost)

        savePosts() // Save the context to persist the new post
    }

    private func savePosts() {
        do {
            try viewContext.save()
            print("Posts saved successfully")
        } catch {
            print("Error saving posts: \(error.localizedDescription)")
        }
    }

    private func uploadCatPostToFirebase(post: CatPost) {
        // Here you can call the Firebase upload function
        // Example: uploadCatPostToFirebase(username: post.username, imageData: post.imageData, ...)
        
        guard let profileImage = profileImage else { return }
        
        // Convert profile image to Data
        let profileImageData = profileImage.asData() // Create a function to convert Image to Data if necessary
        
        // Upload the post data
        uploadCatPostToFirebase(
            profileName: currentUsername,
            profileImage: profileImageData, // Assuming you have the image data
            catName: post.catName ?? "Unknown",
            catBreed: post.catBreed ?? "N/A",
            location: post.location ?? "N/A",
            description: post.postDescription ?? "N/A",
            postImage: postImage // This is the post image you saved in Core Data
        )
    }
}

// Extension to convert SwiftUI Image to Data
extension Image {
    func asData() -> Data? {
        let uiImage = self.asUIImage() // You may need to implement this
        return uiImage?.pngData()
    }

    func asUIImage() -> UIImage? {
        let renderer = ImageRenderer(content: self)
        return renderer.uiImage
    }
}
