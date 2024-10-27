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
                        if !newComment.isEmpty {
                            let comment = Comment(context: viewContext)
                            comment.text = newComment
                            comment.timestamp = Date()
                            comment.catPost = post // Link the comment to the post

                            do {
                                try viewContext.save()
                                newComment = "" // Clear the text field
                            } catch {
                                print("Error saving comment: \(error.localizedDescription)")
                            }
                        }
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
}

// Extension for easier access to the post's comments array
extension CatPost {
    var commentsArray: [Comment] {
        let set = comments as? Set<Comment> ?? []
        return set.sorted { $0.timestamp ?? Date() < $1.timestamp ?? Date() }
    }
}
