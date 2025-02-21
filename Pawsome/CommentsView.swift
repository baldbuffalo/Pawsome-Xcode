import SwiftUI
import FirebaseFirestore

// Comment Model (no change from before)
struct Comment: Identifiable {
    var id: String // Unique identifier for each comment
    var user: String // Name of the user who posted the comment
    var text: String // Content of the comment
    var timestamp: Date // The time the comment was posted
}

// Comments View for displaying the comments of a post
struct CommentsView: View {
    var comments: [Comment] // An array of Comment objects passed from a parent view (e.g., CatPost)

    var body: some View {
        VStack(alignment: .leading) {
            Text("Comments")
                .font(.headline)
                .padding(.top)

            // List of comments for this post
            ForEach(comments) { comment in
                CommentRow(comment: comment)
                    .padding(.vertical, 5)
            }

            // Add your UI for adding comments (if any) below
            // E.g., TextField or TextEditor to add a new comment
        }
        .padding()
    }
}

// Row for each individual comment
struct CommentRow: View {
    var comment: Comment

    var body: some View {
        VStack(alignment: .leading) {
            Text(comment.user)
                .font(.subheadline)
                .foregroundColor(.gray)
            Text(comment.text)
                .font(.body)
                .padding(.top, 2)
            Text("Posted at \(dateFormatter.string(from: comment.timestamp))")
                .font(.footnote)
                .foregroundColor(.gray)
        }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
}
