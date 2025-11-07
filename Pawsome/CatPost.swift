import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct CatPost: Identifiable {
    var id = UUID()
    var name: String
    var description: String
    var imageURL: String
    var userID: String
}

class CatPostViewModel: ObservableObject {
    @Published var posts: [CatPost] = []

    private var db = Firestore.firestore()

    func fetchPosts() {
        db.collection("catPosts").addSnapshotListener { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {
                print("❌ No posts found")
                return
            }

            self.posts = documents.compactMap { doc -> CatPost? in
                let data = doc.data()
                guard let name = data["name"] as? String,
                      let description = data["description"] as? String,
                      let imageURL = data["imageURL"] as? String,
                      let userID = data["userID"] as? String else {
                    return nil
                }
                return CatPost(name: name, description: description, imageURL: imageURL, userID: userID)
            }
        }
    }

    func addPost(name: String, description: String, imageURL: String) {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        db.collection("catPosts").addDocument(data: [
            "name": name,
            "description": description,
            "imageURL": imageURL,
            "userID": userID
        ])
    }
}

struct CatPostView: View {
    @StateObject private var viewModel = CatPostViewModel()
    @State private var name = ""
    @State private var description = ""
    @State private var imageURL = ""

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
                    viewModel.addPost(name: name, description: description, imageURL: imageURL)
                    name = ""
                    description = ""
                    imageURL = ""
                }

                List(viewModel.posts) { post in
                    VStack(alignment: .leading) {
                        Text(post.name).font(.headline)
                        Text(post.description).font(.subheadline)
                        AsyncImage(url: URL(string: post.imageURL)) { image in
                            image.resizable().scaledToFit()
                        } placeholder: {
                            ProgressView()
                        }
                    }
                    .padding()
                }
            }
            .padding()
            .navigationTitle("Cat Posts 😺")
            .onAppear {
                viewModel.fetchPosts()
            }
        }
    }
}
