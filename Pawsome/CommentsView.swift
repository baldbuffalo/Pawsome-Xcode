import SwiftUI
import CoreData

struct CommentsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var userProfile: UserProfile // Inject the UserProfile object
    @Binding var showComments: Bool
    var post: CatPost // The post to which comments belong

    @State private var commentText: String = ""
    @State private var comments: [Comment] = []

    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(post.commentsArray, id: \.self) { comment in
                        HStack {
                            if let imageData = comment.profileImageData, let profileImage = UIImage(data: imageData) {
                                Image(uiImage: profileImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                                    .padding(.trailing, 8)
                            } else if let userProfileImageData = userProfile.profileImageData, let profileImage = UIImage(data: userProfileImageData) {
                                // Use user's profile image data if comment has no image
                                Image(uiImage: profileImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                                    .padding(.trailing, 8)
                            } else {
                                // Default image if no profile image is available
                                Image("defaultProfileImage") // Replace with your default image asset
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                                    .padding(.trailing, 8)
                            }

                            VStack(alignment: .leading) {
                                Text(comment.username ?? "Unknown")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Text(comment.text ?? "")
                                    .font(.body)
                            }
                        }
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
            .navigationTitle("Comments")
            .navigationBarItems(trailing: Button("Close") {
                showComments = false
            })
        }
        .onAppear {
            fetchComments()
        }
    }

    private func fetchComments() {
        // Fetch comments associated with the post
        let request: NSFetchRequest<Comment> = Comment.fetchRequest()
        request.predicate = NSPredicate(format: "post == %@", post)
        
        do {
            comments = try viewContext.fetch(request)
        } catch {
            print("Failed to fetch comments: \(error.localizedDescription)")
        }
    }

    private func saveComment() {
        let newComment = Comment(context: viewContext)
        newComment.text = commentText
        newComment.username = "Your Username" // Replace with the actual username
        newComment.timestamp = Date()

        // Store the user's profile image data from the shared UserProfile object
        newComment.profileImageData = userProfile.profileImageData

        newComment.post = post // Set the relationship

        do {
            try viewContext.save()
            print("Comment saved successfully")
            commentText = "" // Clear the text field after saving
            fetchComments() // Refresh comments list
        } catch {
            print("Error saving comment: \(error.localizedDescription)")
        }
    }
}
