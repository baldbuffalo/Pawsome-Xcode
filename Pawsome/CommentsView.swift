import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct CommentsView: View {
    @EnvironmentObject var profileView: ProfileView // Injected ProfileView object
    @Binding var showComments: Bool
    var postID: String // The ID of the post to which comments belong
    var saveCommentToFirebase: (String, String) -> Void // Closure to save comment to Firebase

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
                        CommentRow(comment: comment)
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
            #if os(iOS)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        showComments = false
                    }
                }
            }
            #elseif os(macOS)
            .navigationBarItems(trailing: Button("Close") {
                showComments = false
            })
            #endif
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

        // Save the comment using the passed closure
        saveCommentToFirebase(postID, commentText)

        // Optionally, update the local comments list
        let newComment = Comment(
            text: commentText,
            username: profileView.username,
            timestamp: Date(),
            profilePictureUrl: profileView.profilePictureUrl
        )

        comments.append(newComment)
        commentText = "" // Clear text field after adding
    }
}

struct CommentRow: View {
    let comment: Comment

    var body: some View {
        HStack {
            // Display profile picture URL or a default image
            if let profilePictureUrl = comment.profilePictureUrl, let url = URL(string: profilePictureUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        .padding(.trailing, 8)
                } placeholder: {
                    Image("defaultProfileImage")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        .padding(.trailing, 8)
                }
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
    var profilePictureUrl: String? // Store the profile picture URL here
}
