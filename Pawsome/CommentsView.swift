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
                // View to display the list of comments
                List {
                    // Accessing comments directly from the CatPost entity
                    if let commentsSet = post.comments as? Set<Comment> {
                        let commentsArray = Array(commentsSet).sorted { ($0.timestamp ?? Date()) < ($1.timestamp ?? Date()) }
                        ForEach(commentsArray, id: \.self) { comment in
                            VStack(alignment: .leading) {
                                HStack {
                                    // Display the user's profile picture
                                    if let imageData = comment.profilePicture {
                                        let profileImage = UIImage(data: imageData)
                                        Image(uiImage: profileImage ?? UIImage())
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 40, height: 40) // Adjust size as needed
                                            .clipShape(Circle())
                                    }

                                    VStack(alignment: .leading) {
                                        Text(comment.username ?? "Anonymous") // Display username
                                            .font(.subheadline)
                                            .fontWeight(.bold)
                                            .foregroundColor(.black)
                                        Text(comment.text ?? "No text") // Display each comment's text
                                            .font(.body)
                                            .foregroundColor(.gray)
                                        Text(comment.timestamp?.formatted() ?? "Unknown date") // Display timestamp
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
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

                // Comment input section
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

        let comment = Comment(context: viewContext) // This Comment refers to your Core Data model
        comment.text = newComment
        comment.timestamp = Date() // Save the current date and time
        comment.username = "YourUsername" // Replace with the actual username
        // Assume you have a way to get the profile picture data
        comment.profilePicture = nil // Set profile picture data if available
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
