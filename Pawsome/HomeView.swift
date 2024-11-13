import SwiftUI
import Firebase

struct HomeView: View {
    @Binding var isLoggedIn: Bool
    @Binding var currentUsername: String
    @Binding var profileImage: Image?

    @State private var showForm: Bool = false
    @State private var selectedImage: UIImage? = nil
    @State private var navigateToHome: Bool = false
    @State private var showComments: Bool = false
    @State private var selectedPost: CatPost? = nil
    @State private var posts: [CatPost] = [] // Array to hold posts fetched from Firebase

    var body: some View {
        NavigationStack {
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

    private func uploadCatPostToFirebase(post: CatPost) {
        guard let profileImage = profileImage else { return }
        
        guard let profileImageData = profileImage.asData() else { return }
        
        let profileImageRef = Storage.storage().reference().child("profileImages/\(currentUsername).jpg")
        profileImageRef.putData(profileImageData, metadata: nil) { metadata, error in
            if let error = error {
                print("Error uploading profile image: \(error.localizedDescription)")
                return
            }

            profileImageRef.downloadURL { url, error in
                if let error = error {
                    print("Error fetching profile image URL: \(error.localizedDescription)")
                    return
                }

                guard let profileImageURL = url else { return }

                if let postImageData = post.imageData {
                    let postImageRef = Storage.storage().reference().child("postImages/\(UUID().uuidString).jpg")
                    postImageRef.putData(postImageData, metadata: nil) { metadata, error in
                        if let error = error {
                            print("Error uploading post image: \(error.localizedDescription)")
                            return
                        }

                        postImageRef.downloadURL { url, error in
                            if let error = error {
                                print("Error fetching post image URL: \(error.localizedDescription)")
                                return
                            }

                            guard let postImageURL = url else { return }

                            let db = Firestore.firestore()
                            let postData: [String: Any] = [
                                "profileName": currentUsername,
                                "profilepicture": profileImageURL.absoluteString,
                                "catName": post.catName ?? "Unknown",
                                "catBreed": post.catBreed ?? "N/A",
                                "location": post.location ?? "N/A",
                                "postdescription": post.postDescription ?? "N/A",
                                "postImage": postImageURL.absoluteString,
                                "timestamp": FieldValue.serverTimestamp()
                            ]

                            db.collection("posts").addDocument(data: postData) { error in
                                if let error = error {
                                    print("Error saving post data: \(error.localizedDescription)")
                                } else {
                                    print("Post saved to Firestore")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
