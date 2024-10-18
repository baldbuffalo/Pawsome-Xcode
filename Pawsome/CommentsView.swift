import SwiftUI

struct CommentsView: View {
    @Binding var showComments: Bool
    @Binding var post: CatPost // Use Binding to update the post with new comments
    
    @State private var newComment: String = ""

    var body: some View {
        NavigationStack {
            VStack {
                List(post.comments, id: \.self) { comment in
                    Text(comment)
                }

                HStack {
                    TextField("Add a comment...", text: $newComment)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    Button("Post") {
                        if !newComment.isEmpty {
                            post.comments.append(newComment) // Append the new comment
                            newComment = "" // Clear the text field
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Comments")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        showComments = false // Close the comments view
                    }
                }
            }
        }
    }
}
