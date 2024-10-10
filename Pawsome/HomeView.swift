import SwiftUI

struct HomeView: View {
    @State private var catPosts: [CatPost] = [] // Array to hold cat posts
    @State private var showForm: Bool = false
    @State private var selectedImage: UIImage? = nil

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                headerView
                postListView
            }
            .navigationTitle("Pawsome")
            .sheet(isPresented: $showForm) {
                // Present the form with bindings
                FormView(showForm: $showForm, catPosts: $catPosts, imageUI: selectedImage)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Trigger image picker here or any method to capture the image
                        // selectedImage = ... (your logic to capture the image)
                        showForm.toggle() // Show the form when image is selected
                    }) {
                        Text("Create Post")
                    }
                }
            }
        }
        .onAppear {
            loadPosts() // Load posts when the view appears
        }
    }

    private var headerView: some View {
        // Your header view implementation here
        Text("Welcome to Pawsome")
            .font(.largeTitle)
            .padding()
    }

    private var postListView: some View {
        List(catPosts) { post in
            // Your post view implementation here
            VStack(alignment: .leading) {
                if let imageData = post.imageData, let image = UIImage(data: imageData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .cornerRadius(12)
                }
                Text(post.name)
                    .font(.headline)
                Text("Breed: \(post.breed)")
                Text("Age: \(post.age)")
                Text("Posted by: \(post.username)")
                Text("Comments: \(post.comments.joined(separator: ", "))")
            }
        }
    }

    private func loadPosts() {
        if let data = UserDefaults.standard.data(forKey: "catPosts"),
           let decodedPosts = try? JSONDecoder().decode([CatPost].self, from: data) {
            catPosts = decodedPosts
        }
    }
}
