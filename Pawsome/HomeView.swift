import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showForm = false
    @State private var selectedImage: UIImage? = nil

    // Fetch existing CatPosts
    @FetchRequest(
        entity: CatPost.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \CatPost.timestamp, ascending: false)]
    ) private var posts: FetchedResults<CatPost>

    var body: some View {
        NavigationView {
            List(posts) { post in
                // Configure how each post is displayed
                Text(post.catName ?? "Unknown Cat")
            }
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showForm.toggle() }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showForm) {
                FormView(
                    showForm: $showForm,
                    currentUsername: "YourUsername",
                    onPostCreated: { newPost in
                        // Refresh or trigger any needed update in HomeView if necessary
                    },
                    selectedImage: $selectedImage
                )
                .environment(\.managedObjectContext, viewContext)
            }
        }
    }
}
