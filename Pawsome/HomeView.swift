import SwiftUI
import Firebase

#if os(iOS)
import UIKit // UIKit for iOS
#elseif os(macOS)
import AppKit // AppKit for macOS
#endif

struct HomeView: View {
    @Binding var isLoggedIn: Bool
    @Binding var currentUsername: String
    @Binding var profileImage: Image?

    @State private var showForm: Bool = false
    @State private var selectedImage: UIImage? = nil // UIImage for iOS
    @State private var navigateToHome: Bool = false
    @State private var showComments: Bool = false
    @State private var selectedPost: CatPost? = nil
    @State private var posts: [CatPost] = [] // Array to hold posts fetched from Firebase
    @StateObject private var profileView = ProfileView() // Create ProfileView as a StateObject

    var body: some View {
        #if os(iOS)
        return NavigationStack {
            contentView
        }
        #elseif os(macOS)
        return NavigationView {
            contentView
        }
        #endif
    }

    private var contentView: some View {
        VStack(spacing: 0) {
            headerView
            postListView
            Spacer()
        }
        .navigationTitle("Pawsome")
        .onAppear {
            fetchPostsFromFirebase() // Fetch posts when view appears
        }
        .sheet(isPresented: $showForm) {
            FormView(
                showForm: $showForm,
                navigateToHome: $navigateToHome,
                imageUI: selectedImage,
                username: currentUsername
            )
        }
        .sheet(isPresented: $showComments) {
            if let selectedPost = selectedPost {
                CommentsView(showComments: $showComments, post: selectedPost) // Pass CatPost directly
                    .environmentObject(profileView) // Inject profileView here
            }
        }
        .onChange(of: navigateToHome) {
            if $0 {
                showForm = false // Dismiss the form
                navigateToHome = false // Reset the navigation state
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
        List(posts) { post in
            VStack(alignment: .leading) {
                Text("Posted by: \(post.username ?? "Unknown")")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.bottom, 2)

                if let imageData = post.imageData {
                    #if os(iOS)
                    if let uiImage = UIImage(data: imageData) { // iOS UIImage
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .cornerRadius(12)
                    }
                    #elseif os(macOS)
                    if let nsImage = NSImage(data: imageData) { // macOS NSImage
                        Image(nsImage: nsImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .cornerRadius(12)
                    }
                    #endif
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
                showComments = true // Show CommentsView when this button is clicked
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

    private func fetchPostsFromFirebase() {
        let db = Firestore.firestore()
        db.collection("posts").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching posts: \(error.localizedDescription)")
                return
            }

            posts = snapshot?.documents.compactMap { document in
                let data = document.data()
                return CatPost(
                    id: document.documentID,
                    username: data["username"] as? String ?? "Unknown",
                    imageData: data["imageData"] as? Data,
                    catName: data["catName"] as? String ?? "Unknown",
                    catBreed: data["catBreed"] as? String ?? "N/A",
                    catAge: data["catAge"] as? Int32 ?? 0,
                    location: data["location"] as? String ?? "N/A",
                    postDescription: data["postDescription"] as? String ?? "N/A",
                    likes: data["likes"] as? Int32 ?? 0
                )
            } ?? []
        }
    }

    private func savePosts() {
        // Implement saving posts if needed
    }

    private func uploadCatPostToFirebase(post: CatPost) {
        // Uploading logic remains the same
    }
}
