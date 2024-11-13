import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct CommentsView: View {
    @EnvironmentObject var profileView: ProfileView // Injected ProfileView object
    @Binding var showComments: Bool
    var postID: String // The ID of the post to which comments belong

    @State private var commentText: String = ""
    @State private var comments: [Comment] = []
    @State private var isLoading = true

    private let db = Firestore.firestore()

    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading Comments...")
                } else {
                    List(comments) { comment in
                        CommentRow(comment: comment, profileView: profileView)
                    }
                }

                HStack {
                    TextField("Add a comment...", text: $commentText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()

                    Button(action: saveComment) {
                        Text("Send")
                            .bold()
                    }
                    .padding()
                }
            }
            .onAppear {
                Task {
                    await loadComments()
                }
            }
            .navigationTitle("Comments")
            .navigationBarItems(trailing: Button("Close") {
                showComments = false
            })
        }
    }

    private func loadComments() async {
        do {
            let snapshot = try await db.collection("posts").document(postID).collection("comments")
                .order(by: "timestamp", descending: false)
                .getDocuments()
            
            comments = snapshot.documents.compactMap { document in
                try? document.data(as: Comment.self)
            }
        } catch {
            print("Failed to fetch comments: \(error.localizedDescription)")
        }
        isLoading = false
    }

    private func saveComment() {
        guard !commentText.isEmpty else { return }

        let newComment = Comment(
            text: commentText,
            username: profileView.username,
            timestamp: Date(),
            profilePictureUrl: profileView.profilePictureUrl // Assuming you are storing the profile picture URL here
        )

        Task {
            do {
                let commentRef = db.collection("posts").document(postID).collection("comments")
                _ = try commentRef.addDocument(from: newComment)
                comments.append(newComment)
                commentText = "" // Clear text field after adding
            } catch {
                print("Failed to save comment: \(error.localizedDescription)")
            }
        }
    }
}

struct CommentRow: View {
    let comment: Comment
    let profileView: ProfileView

    var body: some View {
        HStack {
            if let profilePicture = profileView.profilePicture {
                profilePicture
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .padding(.trailing, 8)
            } else {
                Image("defaultProfileImage")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .padding(.trailing, 8)
            }

            VStack(alignment: .leading) {
                Text(comment.username)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text(comment.text)
                    .font(.body)
            }
        }
    }
}

struct Comment: Identifiable, Codable {
    @DocumentID var id: String?
    var text: String
    var username: String
    var timestamp: Date
    var profilePictureUrl: String?
}

struct ProfileView: View {
    @State private var profilePicture: Image? // To store the profile image in memory
    @State var profilePictureUrl: String? // URL for profile image from Firestore
    var username: String = "User123" // Example username
    
    var body: some View {
        VStack {
            if let profilePicture = profilePicture {
                profilePicture
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
            } else {
                Image("defaultProfileImage")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
            }

            Text(username)
                .font(.title)
                .padding()
        }
        .onAppear {
            Task {
                await loadProfilePicture()
            }
        }
    }

    func loadProfilePicture() async {
        let db = Firestore.firestore()
        let userID = Auth.auth().currentUser?.uid ?? "unknownUserID"
        let userRef = db.collection("users").document(userID)

        do {
            let document = try await userRef.getDocument()
            if let data = document.data(), let imageUrlString = data["profileImageUrl"] as? String {
                profilePictureUrl = imageUrlString

                if let imageUrl = URL(string: imageUrlString) {
                    if let imageData = try? Data(contentsOf: imageUrl), let uiImage = UIImage(data: imageData) {
                        profilePicture = Image(uiImage: uiImage)
                    }
                }
            }
        } catch {
            print("Failed to fetch profile image: \(error.localizedDescription)")
        }
    }
}
