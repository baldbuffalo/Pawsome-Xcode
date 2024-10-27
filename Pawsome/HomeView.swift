import SwiftUI
import CoreData

struct HomeView: View {
    @Binding var isLoggedIn: Bool
    @Binding var currentUsername: String
    @Binding var profileImage: Image?

    @State private var selectedImage: UIImage? = nil
    @State private var showForm: Bool = false
    @State private var navigateToHome: Bool = false
    @State private var isTabViewHidden: Bool = false // New state variable

    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        entity: CatPost.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \CatPost.timestamp, ascending: false)]
    ) var catPosts: FetchedResults<CatPost>

    var body: some View {
        Group {
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
                                savePost(from: newPost)
                            }
                        }
                    }
                    .onChange(of: navigateToHome) { _ in
                        showForm = false
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
                            if let capturedImage = post.imageData {
                                savePost(from: post)
                            }
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
            .opacity(isTabViewHidden ? 0 : 1) // Hide tab view based on state
        }
        .overlay {
            // This overlay hides the TabView when CommentsView is shown
            if isTabViewHidden {
                Color.clear
                    .onTapGesture {
                        // Do nothing to prevent interaction with the overlay
                    }
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
        VStack {
            // Delete All Posts Button
            Button(action: {
                deleteAllPosts()
            }) {
                Text("Delete All Posts")
                    .fontWeight(.bold)
                    .foregroundColor(.red)
            }
            .padding()
            .alert(isPresented: .constant(catPosts.isEmpty == false)) {
                Alert(
                    title: Text("Confirmation"),
                    message: Text("Are you sure you want to delete all posts?"),
                    primaryButton: .destructive(Text("Delete")) {
                        deleteAllPosts()
                    },
                    secondaryButton: .cancel()
                )
            }

            List {
                ForEach(catPosts, id: \.self) { post in
                    VStack(alignment: .leading) {
                        Text("Posted by: \(post.username ?? "")")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.bottom, 2)

                        if let imageData = post.imageData, let image = UIImage(data: imageData) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .cornerRadius(12)
                        }

                        Text(post.catName ?? "")
                            .font(.headline)
                        Text("Breed: \(post.catBreed ?? "")")

                        let ageDisplay = post.catAge > 0 ? "\(post.catAge)" : "Unknown"
                        Text("Age: \(ageDisplay)")

                        Text("Location: \(post.location ?? "")")
                        Text("Description: \(post.postDescription ?? "")")

                        if let timestamp = post.timestamp {
                            Text("Posted on: \(formattedDate(timestamp))")
                                .font(.footnote)
                                .foregroundColor(.gray)
                        }

                        HStack {
                            Button(action: {
                                post.likes = post.likes > 0 ? 0 : 1
                                saveContext()
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
                                .onAppear {
                                    isTabViewHidden = true // Hide tab items when CommentsView appears
                                }
                                .onDisappear {
                                    isTabViewHidden = false // Show tab items when CommentsView disappears
                                }) {
                                HStack {
                                    Image(systemName: "message")
                                    Text("Comment")
                                }
                            }
                            .buttonStyle(BorderlessButtonStyle())

                            if post.username == currentUsername {
                                Button(action: {
                                    deletePost(post: post)
                                }) {
                                    HStack {
                                        Image(systemName: "trash")
                                        Text("Delete")
                                    }
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            }
                        }
                        .padding(.top, 5)
                    }
                    .padding(.vertical)
                }
            }
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func savePost(from newPost: CatPost) {
        let catPost = CatPost(context: viewContext)
        catPost.username = currentUsername
        catPost.imageData = newPost.imageData
        catPost.catName = newPost.catName
        catPost.catBreed = newPost.catBreed
        catPost.catAge = newPost.catAge
        catPost.location = newPost.location
        catPost.postDescription = newPost.postDescription
        catPost.timestamp = Date()
        catPost.likes = 0

        saveContext()
    }

    private func deletePost(post: CatPost) {
        viewContext.delete(post)
        saveContext()
    }

    private func deleteAllPosts() {
        for post in catPosts {
            viewContext.delete(post)
        }
        saveContext()
    }

    private func saveContext() {
        if viewContext.hasChanges {
            do {
                try viewContext.save()
            } catch {
                print("Failed to save context: \(error)")
            }
        }
    }
}
