import SwiftUI

struct CatPostView: View {
    @State private var name = ""
    @State private var description = ""
    @State private var imageURL = ""
    @State private var posts: [CatPost] = []

    struct CatPost: Identifiable {
        var id = UUID()
        var name: String
        var description: String
        var imageURL: String
    }

    var body: some View {
        NavigationView {
            VStack {
                TextField("Cat Name", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                TextField("Description", text: $description)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                TextField("Image URL", text: $imageURL)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Button("Post 🐾") {
                    // For testing: do nothing
                    name = ""
                    description = ""
                    imageURL = ""
                }
                .padding(.vertical)

                List(posts) { post in
                    VStack(alignment: .leading) {
                        Text(post.name).font(.headline)
                        Text(post.description).font(.subheadline)
                        if let url = URL(string: post.imageURL) {
                            AsyncImage(url: url) { image in
                                image.resizable().scaledToFit()
                            } placeholder: {
                                ProgressView()
                            }
                        }
                    }
                    .padding()
                }
            }
            .padding()
            .navigationTitle("Cat Posts 😺")
        }
    }
}
