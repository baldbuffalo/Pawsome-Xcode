import Firebase

class CatPostViewModel: ObservableObject {
    @Published var catPosts: [CatPost] = []

    func fetchPosts() {
        let db = Firestore.firestore()
        db.collection("posts").order(by: "timestamp", descending: true).getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching posts: \(error)")
                return
            }

            if let snapshot = snapshot {
                self.catPosts = snapshot.documents.compactMap { document in
                    try? document.data(as: CatPost.self)
                }
            }
        }
    }
}
