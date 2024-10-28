import SwiftUI
<<<<<<< HEAD

struct CommentsView: View {
    @Binding var showComments: Bool
    @Binding var post: CatPost // Use Binding to update the post with new comments
    
=======
import CoreData

// View to display the list of comments
struct CommentsListView: View {
    @ObservedObject var post: CatPost // ObservedObject for the CatPost

    var body: some View {
        List {
            // Accessing comments directly from the CatPost entity
            if let commentsSet = post.comments as? Set<Comment> {
                let commentsArray = Array(commentsSet).sorted { ($0.timestamp ?? Date()) < ($1.timestamp ?? Date()) }
                ForEach(commentsArray, id: \.self) { comment in
                    VStack(alignment: .leading) {
                        Text(comment.username ?? "Anonymous") // Display username
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                        Text(comment.text ?? "No text") // Display each comment's text
                            .font(.body)
                            .foregroundColor(.gray)
                    }
                    .padding(10)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(radius: 1)
                    .listRowSeparator(.hidden)
                }
            } else {
                // Handle the case where comments is nil or cannot be cast
                Text("No comments available.")
                    .foregroundColor(.gray)
                    .padding()
            }
        }
        .listStyle(PlainListStyle())
        .padding(.top)
    }
}

// View for adding a new comment
struct CommentInputView: View {
    @Binding var newComment: String
    var post: CatPost // Reference to the CatPost to link the comment

    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        HStack {
            TextField("Add a comment...", text: $newComment)
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(20)
                .padding(.trailing, 8)

            Button(action: postComment) {
                Text("Post")
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                    .padding(10)
                    .background(Color.clear)
                    .cornerRadius(20)
            }
            .disabled(newComment.isEmpty)
        }
        .padding()
    }

    private func postComment() {
        guard !newComment.isEmpty else { return }

        let comment = Comment(context: viewContext) // This Comment refers to your Core Data model
        comment.text = newComment
        comment.timestamp = Date()
        comment.username = "YourUsername" // Replace with the actual username
        comment.profilePicture = nil // Replace with actual image data if available
        comment.catPost = post // Link the comment to the post

        // Add the comment to the CatPost's comments set
        var commentsSet = post.comments as? Set<Comment> ?? []
        commentsSet.insert(comment)
        post.comments = NSSet(set: commentsSet)

        do {
            try viewContext.save() // Save the new comment to Core Data
            newComment = "" // Clear the text field after saving
        } catch {
            print("Error saving comment: \(error.localizedDescription)")
        }
    }
}

// Main view for comments
struct CommentsView: View {
    @Binding var showComments: Bool
    var post: CatPost // Use the CatPost class from CatPost+CoreDataClass.swift

>>>>>>> 5eef0f8bd39986f9f45e071df446cc125709c1b6
    @State private var newComment: String = ""

    var body: some View {
        NavigationStack {
            VStack {
<<<<<<< HEAD
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
=======
                // Use the CommentsListView to display comments
                CommentsListView(post: post)

                // Comment input section
                CommentInputView(newComment: $newComment, post: post)
>>>>>>> 5eef0f8bd39986f9f45e071df446cc125709c1b6
            }
            .navigationTitle("Comments")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
<<<<<<< HEAD
                        showComments = false // Close the comments view
=======
                        showComments = false
>>>>>>> 5eef0f8bd39986f9f45e071df446cc125709c1b6
                    }
                }
            }
        }
<<<<<<< HEAD
=======
        .background(Color(.systemGroupedBackground))
        .edgesIgnoringSafeArea(.bottom)
>>>>>>> 5eef0f8bd39986f9f45e071df446cc125709c1b6
    }
}
