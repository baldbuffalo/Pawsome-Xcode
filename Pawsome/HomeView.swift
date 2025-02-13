import SwiftUI
import Firebase
import FirebaseFirestore

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var selectedPost: CatPost?
    @State private var postToDelete: CatPost?
    @State private var showError = false
    @State private var isAddingPost = false
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading posts...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.posts.isEmpty {
                    EmptyStateView()
                } else {
                    PostsListView()
                }
            }
            .navigationTitle("Pawsome")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isAddingPost = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .alert("Error", isPresented: $showError, presenting: viewModel.error) { _ in } message: {
                Text($0.localizedDescription)
            }
            .confirmationDialog("Delete Post", isPresented: Binding(
                get: { postToDelete != nil },
                set: { _ in postToDelete = nil }
            )) {
                DeleteConfirmationButtons()
            }
            .sheet(item: $selectedPost) { post in
                EditPostView(post: post) { updatedPost in
                    viewModel.updatePost(updatedPost)
                }
            }
            .sheet(isPresented: $isAddingPost) {
                AddPostView { newPost in
                    viewModel.savePost(newPost)
                }
            }
            .refreshable { viewModel.fetchPosts() }
            .onAppear { viewModel.fetchPostsIfNeeded() }
        }
    }
    
    // MARK: - Subviews
    
    private func PostsListView() -> some View {
        List {
            ForEach(viewModel.posts) { post in
                PostCardView(post: post)
                    .swipeActions(edge: .trailing) {
                        SwipeDeleteButton(post: post)
                        SwipeEditButton(post: post)
                    }
                    .contextMenu {
                        EditButton(post: post)
                        DeleteButton(post: post)
                    }
            }
        }
        .listStyle(.plain)
    }
    
    private func SwipeDeleteButton(post: CatPost) -> some View {
        Button(role: .destructive) {
            postToDelete = post
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
    
    private func SwipeEditButton(post: CatPost) -> some View {
        Button {
            selectedPost = post
        } label: {
            Label("Edit", systemImage: "pencil")
        }
        .tint(.blue)
    }
    
    private func DeleteConfirmationButtons() -> some View {
        Group {
            Button("Delete", role: .destructive) {
                if let post = postToDelete {
                    viewModel.deletePost(post)
                }
            }
            Button("Cancel", role: .cancel) { }
        }
    }
}

// MARK: - ViewModel

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var posts: [CatPost] = []
    @Published var isLoading = true
    @Published var error: Error?
    
    private var lastFetchTime = Date.distantPast
    private let cacheDuration: TimeInterval = 300 // 5 minutes
    
    // Fetch posts from Firebase
    func fetchPostsIfNeeded() {
        guard Date().timeIntervalSince(lastFetchTime) > cacheDuration else { return }
        fetchPosts()
    }
    
    func fetchPosts() {
        isLoading = true
        Task {
            do {
                let query = Firestore.firestore().collection("posts")
                    .order(by: "timestamp", descending: true)
                
                let snapshot = try await query.getDocuments()
                posts = try snapshot.documents.compactMap { document in
                    try document.data(as: CatPost.self)
                }
                lastFetchTime = Date()
                isLoading = false
            } catch {
                handleError(error)
            }
        }
    }
    
    // Save a new post to Firebase
    func savePost(_ post: CatPost) {
        Task {
            do {
                let documentRef = Firestore.firestore().collection("posts").document(post.id)
                try documentRef.setData(from: post)
                withAnimation {
                    posts.insert(post, at: 0) // Add the new post to the top of the list
                }
            } catch {
                handleError(error)
            }
        }
    }
    
    // Delete a post from Firebase
    func deletePost(_ post: CatPost) {
        Task {
            do {
                try await Firestore.firestore().collection("posts")
                    .document(post.id).delete()
                withAnimation {
                    posts.removeAll { $0.id == post.id }
                }
            } catch {
                handleError(error)
            }
        }
    }
    
    // Update a post in Firebase
    func updatePost(_ post: CatPost) {
        Task {
            do {
                let documentRef = Firestore.firestore().collection("posts").document(post.id)
                try documentRef.setData(from: post, merge: true)
                if let index = posts.firstIndex(where: { $0.id == post.id }) {
                    posts[index] = post
                }
            } catch {
                handleError(error)
            }
        }
    }
    
    // Handle errors
    private func handleError(_ error: Error) {
        self.error = error
        isLoading = false
    }
}

// MARK: - Subviews

struct PostCardView: View {
    let post: CatPost
    @State private var showComments = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(post.catName)
                    .font(.title2.bold())
                
                Spacer()
                
                Text("\(post.likes) ♥️")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if let imageURL = post.imageURL {
                AsyncImage(url: URL(string: imageURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(12)
                    case .failure:
                        Image(systemName: "xmark.circle")
                            .foregroundColor(.red)
                    case .empty:
                        ProgressView()
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                if let breed = post.catBreed {
                    Text(breed)
                        .font(.subheadline)
                }
                
                Text("Age: \(post.catAge) years")
                    .font(.subheadline)
                
                if let location = post.location {
                    Text(location)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                NavigationLink {
                    CommentsView(post: post)
                } label: {
                    Label("\(post.comments.count)", systemImage: "bubble.right")
                }
                
                Spacer()
                
                Button {
                    // Implement like functionality
                } label: {
                    Label("Like", systemImage: "heart")
                }
                
                Button {
                    // Implement share functionality
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            }
            .buttonStyle(.bordered)
        }
        .padding(.vertical)
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "pawprint")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Posts Found")
                .font(.title2)
                .foregroundColor(.primary)
            
            Text("Be the first to share your feline friend!")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct AddPostView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var catName: String = ""
    @State private var catBreed: String = ""
    @State private var catAge: String = ""
    @State private var location: String = ""
    @State private var imageURL: String = ""
    
    var onSave: (CatPost) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Cat Information")) {
                    TextField("Cat Name", text: $catName)
                    TextField("Breed", text: $catBreed)
                    TextField("Age", text: $catAge)
                        .keyboardType(.numberPad)
                    TextField("Location", text: $location)
                    TextField("Image URL", text: $imageURL)
                }
                
                Section {
                    Button("Save") {
                        savePost()
                    }
                    .disabled(catName.isEmpty || catAge.isEmpty || imageURL.isEmpty)
                    
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .navigationTitle("Add Post")
        }
    }
    
    private func savePost() {
        guard let age = Int(catAge) else { return }
        let newPost = CatPost(id: UUID().uuidString, catName: catName, catBreed: catBreed, catAge: age, location: location, imageURL: imageURL, likes: 0, comments: [])
        onSave(newPost)
        dismiss()
    }
}

struct CatPost: Identifiable, Codable {
    var id: String
    var catName: String
    var catBreed: String?
    var catAge: Int
    var location: String?
    var imageURL: String?
    var likes: Int
    var comments: [String]
}
