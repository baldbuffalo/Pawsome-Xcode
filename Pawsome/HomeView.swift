import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CatPost.timestamp, ascending: false)],
        animation: .default)
    private var posts: FetchedResults<CatPost>

    var currentUsername: String
    @Binding var profileImage: UIImage?

    @State private var showForm = false // State variable to show the form
    @State private var selectedImage: UIImage? // State variable to hold the selected image

    var body: some View {
        NavigationStack {
            VStack {
                Text("Welcome to Pawsome!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()

                // Display a message if no posts are available
                if posts.isEmpty {
                    Text("No posts yet! Start by creating a new one.")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    // List to display CatPosts
                    List {
                        ForEach(posts) { post in
                            VStack(alignment: .leading) {
                                HStack {
                                    Text("Posted by \(post.username ?? currentUsername)")
                                        .font(.headline)
                                        .foregroundColor(.blue)
                                    Spacer()
                                    // Menu for Edit and Delete options
                                    Menu {
                                        Button(action: {
                                            // Handle Edit action
                                            print("Edit post with ObjectID: \(post.objectID)")
                                        }) {
                                            Text("Edit")
                                        }
                                        Button(action: {
                                            // Handle Delete action
                                            deletePost(post: post)
                                        }) {
                                            Text("Delete")
                                                .foregroundColor(.red)
                                        }
                                    } label: {
                                        Image(systemName: "ellipsis")
                                            .foregroundColor(.blue)
                                            .padding(8)
                                            .background(Circle().fill(Color.gray.opacity(0.2)))
                                    }
                                }

                                // Displaying image
                                if let imageData = post.imageData, let uiImage = UIImage(data: imageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 200)
                                        .cornerRadius(10)
                                        .padding(.top)
                                } else {
                                    Text("No media available.")
                                        .foregroundColor(.gray)
                                        .padding(.top)
                                }

                                // Display the user's input under the media
                                Text(post.content ?? "No content")
                                    .font(.subheadline)
                                    .padding(.top, 5)
                                    .foregroundColor(.black)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .listStyle(PlainListStyle()) // Optional for performance
                }

                Spacer()
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showForm) {
                FormView(showForm: $showForm, currentUsername: currentUsername, onPostCreated: { newPost in
                    // The new post will automatically appear in the list
                    print("New post created: \(newPost)")
                    // No need for additional actions; FetchRequest automatically updates the list
                }, selectedImage: $selectedImage) // Pass the selected image binding if needed
            }
        }
    }

    // Function to delete posts
    private func deletePost(post: CatPost) {
        withAnimation {
            viewContext.delete(post)
            saveContext()
        }
    }

    // Function to save context changes to Core Data
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            print("Unresolved error \(nsError), \(nsError.userInfo)")
            // Provide feedback to the user if needed
        }
    }
}
