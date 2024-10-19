import SwiftUI

struct CommentsView: View {
    @Binding var showComments: Bool
    @Binding var post: CatPost // Use Binding to update the post with new comments

    @State private var newComment: String = ""

    var body: some View {
        NavigationStack {
            VStack {
                List {
                    ForEach(post.comments, id: \.self) { comment in
                        // Styling each comment to resemble Instagram's comments
                        Text(comment)
                            .padding(10) // Add padding for spacing
                            .background(Color.white) // Background color
                            .cornerRadius(10) // Rounded corners
                            .shadow(radius: 1) // Subtle shadow for depth
                            .listRowSeparator(.hidden) // Hide default row separators
                    }
                }
                .listStyle(PlainListStyle()) // Use plain list style for minimal look
                .padding(.top)

                // Comment input area styled like Instagram
                HStack {
                    TextField("Add a comment...", text: $newComment)
                        .padding(10)
                        .background(Color(.systemGray6)) // Light gray background
                        .cornerRadius(20) // Rounded corners
                        .padding(.trailing, 8) // Space between TextField and button

                    Button(action: {
                        if !newComment.isEmpty {
                            post.comments.append(newComment) // Append the new comment
                            newComment = "" // Clear the text field
                        }
                    }) {
                        Text("Post")
                            .fontWeight(.bold) // Bold font for emphasis
                            .foregroundColor(.blue) // Use a blue color for the button text
                            .padding(10)
                            .background(Color.clear) // Clear background for button
                            .cornerRadius(20) // Rounded corners
                    }
                    .disabled(newComment.isEmpty) // Disable button if no text
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
        .background(Color(.systemGroupedBackground)) // Background color for the whole view
        .edgesIgnoringSafeArea(.bottom) // Extend the background color to the bottom
    }
}
