import SwiftUI
import CoreData

struct CommentsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var profileView: ProfileView // Inject the ProfileView object
    @Binding var showComments: Bool
    var post: CatPost // The post to which comments belong

    @State private var commentText: String = ""

    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(post.commentsArray, id: \.self) { comment in
                        HStack {
                            // Display profile image or default image
                            if let imageData = comment.profileImageData, let profileImage = imageFromData(imageData) {
                                profileImage
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                                    .padding(.trailing, 8)
                            } else if let userProfileImageData = profileView.profileImageData, let profileImage = imageFromData(userProfileImageData) {
                                // Use profile image data if no image in the comment
                                profileImage
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
                                // Use the username from ProfileView
                                Text(profileView.username) // Get the username from ProfileView object
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
    }

    private func saveComment() {
        guard !commentText.isEmpty else { return }

        let newComment = Comment(context: viewContext)
        newComment.text = commentText
        newComment.username = profileView.username // Use the username from ProfileView object
        newComment.timestamp = Date()

        // Store the profile image data from the ProfileView object
        newComment.profileImageData = profileView.profileImageData

        newComment.post = post // Set the relationship

        do {
            try viewContext.save()
            print("Comment saved successfully")
            commentText = "" // Clear the text field after saving
        } catch {
            print("Error saving comment: \(error.localizedDescription)")
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
