import SwiftUI
import CoreData

struct HomeView: View {
    @Binding var isLoggedIn: Bool
    @Binding var currentUsername: String
    @Binding var profileImage: Image?

    @State private var selectedImage: UIImage? = nil
    @State private var showForm: Bool = false
    @State private var navigateToHome: Bool = false
    @State private var isTabViewHidden: Bool = false

    @Environment(\.managedObjectContext) private var viewContext
    
    // Fetch CatPosts from Core Data sorted by timestamp
    @FetchRequest(
        entity: CatPost.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \CatPost.timestamp, ascending: false)] // Sort by timestamp
    ) var catPosts: FetchedResults<CatPost>

    var body: some View {
        Group {
            if !isTabViewHidden {
                TabView {
                    NavigationStack {
                        VStack(spacing: 0) {
                            headerView
                            postListView
                            Spacer()
                        }
                        .navigationTitle("Pawsome")
                        .sheet(isPresented: $showForm) {
                            if let selectedImage = selectedImage {
                                FormView(showForm: $showForm, navigateToHome: $navigateToHome, imageUI: selectedImage, videoURL: nil, username: currentUsername) { newPost in
                                    // Handle new post logic here, if necessary
                                }
                            }
                        }
                        .onChange(of: navigateToHome) { newValue in
                            if newValue {
                                showForm = false
                            }
                        }
                    }
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }

                    NavigationStack {
                        ScanView(
                            capturedImage: $selectedImage,
                            username: currentUsername,
                            onPostCreated: { post in
                                // Save the new post to Core Data
                                savePost(post) // Implement this function to save the post
                            }
                        )
                    }
                    .tabItem {
                        Label("Post", systemImage: "camera")
                    }

                    NavigationStack {
                        ProfileView(isLoggedIn: $isLoggedIn, currentUsername: $currentUsername, profileImage: $profileImage)
                            .navigationTitle("Profile")
                    }
                    .tabItem {
                        Label("Profile", systemImage: "person")
                    }
                }
                .tabViewStyle(DefaultTabViewStyle())
            }
        }
    }

    private var headerView: some View {
        VStack {
            Text("Welcome to Pawsome")
                .font(.largeTitle)
                .padding()
            Text("Hello, \(currentUsername)")
                .font(.subheadline)
                .padding(.bottom)
        }
    }

    private var postListView: some View {
        List {
            ForEach(catPosts, id: \.self) { post in
                VStack(alignment: .leading) {
                    Text("Posted by: \(post.username ?? "")") // Uses Core Data property 'username'
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.bottom, 2)

                    if let imageData = post.imageData, let image = UIImage(data: imageData) { // Uses Core Data property 'imageData'
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .cornerRadius(12)
                    }

                    Text(post.name ?? "") // Uses Core Data property 'name'
                        .font(.headline)
                    Text("Breed: \(post.breed ?? "")") // Uses Core Data property 'breed'
                    
                    // Uses Core Data property for age
                    Text("Age: \(post.age ?? "Unknown")") // Uses Core Data property 'age'

                    Text("Location: \(post.location ?? "")") // Uses Core Data property 'location'
                    Text("Description: \(post.postDescription ?? "")") // Uses Core Data property 'postDescription'
                    
                    // Display the timestamp
                    if let timestamp = post.timestamp { // Uses Core Data property 'timestamp'
                        Text("Posted on: \(formattedDate(timestamp))")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    }

                    HStack {
                        Button(action: {
                            post.likes = post.likes > 0 ? 0 : 1 // Uses Core Data property 'likes'
                            // Save context if necessary
                        }) {
                            HStack {
                                Image(systemName: post.likes > 0 ? "hand.thumbsup.fill" : "hand.thumbsup")
                                Text("Like (\(post.likes))")
                            }
                            .padding()
                            .background(Color.white.opacity(0.5))
                            .cornerRadius(8)
                        }
                        .buttonStyle(BorderlessButtonStyle())

                        Spacer()

                        NavigationLink(destination: CommentsView(showComments: .constant(true), post: post)
                            .onAppear { isTabViewHidden = true }
                            .onDisappear { isTabViewHidden = false }) {
                            HStack {
                                Image(systemName: "message")
                                Text("Comment")
                            }
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    .padding(.top, 5)
                }
                .padding(.vertical)
            }
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func savePost(_ post: CatPost) {
        // Implement your saving logic here
        // Remember to save the context
    }
}
