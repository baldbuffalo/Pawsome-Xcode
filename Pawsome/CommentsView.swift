import SwiftUI
import FirebaseFirestore

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
            
            comments = snapshot.documents.compactMap { try? $0.data(as: Comment.self) }
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
            profileImageData: profileView.profileImageData
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
            if let imageData = comment.profileImageData, let image = imageFromData(imageData) {
                image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .padding(.trailing, 8)
            } else if let userImageData = profileView.profileImageData, let image = imageFromData(userImageData) {
                image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .padding(.trailing, 8)
            } else {
                Image("defaultProfileImage") // Default profile image
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

    private func imageFromData(_ data: Data) -> Image? {
        #if os(iOS)
        if let uiImage = UIImage(data: data) {
            return Image(uiImage: uiImage)
        }
        #else
        if let nsImage = NSImage(data: data) {
            return Image(nsImage: nsImage)
        }
        #endif
        return nil
    }
}
