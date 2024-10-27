import SwiftUI
import CoreData

struct CommentsView: View {
    @Binding var showComments: Bool
    @Binding var post: CatPost // Use the CatPost class from CatPost+CoreDataClass.swift

    @Environment(\.managedObjectContext) private var viewContext
    @State private var newComment: String = ""

    var body: some View {
        NavigationStack {
            VStack {
                List {
                    ForEach(post.commentsArray, id: \.self) { comment in
                        Text(comment.text ?? "No text") // Display each comment's text
                            .padding(10)
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(radius: 1)
                            .listRowSeparator(.hidden)
                    }
                }
                .listStyle(PlainListStyle())
                .padding(.top)

                HStack {
                    TextField("Add a comment...", text: $newComment)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(20)
                        .padding(.trailing, 8)

                    Button(action: {
                        postComment() // Call a method to handle posting the comment
                    }) {
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
            .navigationTitle("Comments")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        showComments = false
                    }
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .edgesIgnoringSafeArea(.bottom)
    }

    private func postComment() {
        guard !newComment.isEmpty else { return }

        let comment = Comment(context: viewContext)
        comment.text = newComment
        comment.timestamp = Date()
        comment.catPost = post // Link the comment to the post

        do {
            try viewContext.save() // Save the new comment to Core Data
            newComment = "" // Clear the text field after saving
        } catch {
            // Handle the error appropriately (e.g., show an alert)
            print("Error saving comment: \(error.localizedDescription)")
        }
    }
}

// Extension for easier access to the post's comments array
extension CatPost {
    var commentsArray: [Comment] {
        let set = comments as? Set<Comment> ?? []
        return set.sorted { $0.timestamp ?? Date() < $1.timestamp ?? Date() }
    }
}
