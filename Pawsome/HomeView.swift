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

    @State private var showForm = false
    @State private var selectedImage: UIImage?

    var body: some View {
        NavigationStack {
            VStack {
                Text("Welcome to Pawsome!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()

                if posts.isEmpty {
                    Text("No posts yet! Start by creating a new one.")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List {
                        ForEach(posts) { post in
                            VStack(alignment: .leading) {
                                HStack {
                                    Text("Posted by \(post.username ?? currentUsername)")
                                        .font(.headline)
                                        .foregroundColor(.blue)
                                    Spacer()
                                    Menu {
                                        Button(action: {
                                            // Handle Edit action
                                            print("Edit post with ObjectID: \(post.objectID)")
                                        }) {
                                            Text("Edit")
                                        }
                                        Button(action: {
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

                                Text(post.content ?? "No content")
                                    .font(.subheadline)
                                    .padding(.top, 5)
                                    .foregroundColor(.black)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .listStyle(PlainListStyle())
                }

                Spacer()
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showForm) {
                FormView(showForm: $showForm, currentUsername: currentUsername, onPostCreated: { newPost in
                    // This closure will be called when a new post is created
                    print("New post created: \(newPost)")
                    // This action can be extended to include additional logic if needed
                }, selectedImage: $selectedImage)
                .environment(\.managedObjectContext, viewContext) // Pass the context to FormView
            }
        }
    }

    private func deletePost(post: CatPost) {
        withAnimation {
            viewContext.delete(post)
            saveContext()
        }
    }

    private func saveContext() {
        do {
            try viewContext.save()
        } catch let error as NSError {
            print("Unresolved error \(error), \(error.userInfo)")
        }
    }
}
