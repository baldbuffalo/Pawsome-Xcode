import SwiftUI

struct HomeView: View {
    @Binding var isLoggedIn: Bool
    @State private var catPosts: [CatPost] = []
    @State private var showScanView = false
    @State private var capturedImage: UIImage? = nil
    @State private var selectedTab = 0
    @State private var currentUsername = "User" // Placeholder for username

    // Track liked post IDs for the current user
    @State private var likedPostIDs: Set<UUID> = []

    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            VStack(spacing: 0) {
                Text("Welcome to Pawsome!")
                    .font(.largeTitle)
                    .padding()

                Text("Explore the latest posts about adorable cats.")
                    .font(.subheadline)
                    .padding(.bottom, 20)

                List {
                    ForEach($catPosts) { $post in
                        VStack(alignment: .leading, spacing: 12) {
                            // Post header (Profile pic, Username, Time)
                            HStack {
                                Image(systemName: "person.circle.fill") // Placeholder for user profile image
                                    .resizable()
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                                
                                VStack(alignment: .leading) {
                                    Text(post.username) // Display username from post
                                        .font(.headline)
                                    Text(formatPostTime(post.creationTime)) // Format and display post time
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal)

                            // Cat image content
                            if let image = post.image {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 300)
                                    .cornerRadius(12)
                                    .padding(.horizontal)
                            }

                            // Like and Comment actions
                            HStack {
                                // Like Button
                                Button(action: {
                                    if !likedPostIDs.contains(post.id) {
                                        post.likes += 1
                                        likedPostIDs.insert(post.id)
                                        savePosts() // Save changes
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: likedPostIDs.contains(post.id) ? "heart.fill" : "heart")
                                            .foregroundColor(likedPostIDs.contains(post.id) ? .red : .gray)
                                        Text("\(post.likes)")
                                            .foregroundColor(.primary)
                                    }
                                }
                                .buttonStyle(BorderlessButtonStyle()) // Allow it to work inside list
                                
                                Spacer()

                                // Comments
                                Button(action: {
                                    // Handle comment button action
                                }) {
                                    HStack {
                                        Image(systemName: "bubble.right")
                                        Text("\(post.comments.count) Comments")
                                    }
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            }
                            .padding(.horizontal)

                            // Description and Comments Section
                            VStack(alignment: .leading, spacing: 5) {
                                Text(post.name)
                                    .font(.headline)
                                    .padding(.horizontal)

                                Text("Breed: \(post.breed) • Age: \(post.age)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)

                                // Comments
                                ForEach(post.comments.prefix(2), id: \.self) { comment in
                                    HStack {
                                        Image(systemName: "person.circle.fill") // Comment user icon placeholder
                                            .resizable()
                                            .frame(width: 24, height: 24)
                                            .clipShape(Circle())
                                        
                                        Text(comment)
                                            .font(.subheadline)
                                            .padding(.leading, 5)
                                    }
                                    .padding(.horizontal)
                                }

                                if post.comments.count > 2 {
                                    Button(action: {
                                        // Handle showing more comments
                                    }) {
                                        Text("View all \(post.comments.count) comments")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                            .padding(.horizontal)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(radius: 3)
                        .padding(.horizontal)
                    }
                }
                .listStyle(PlainListStyle()) // Remove default list separators
            }
            .tabItem {
                Image(systemName: "house.fill")
                Text("Home")
            }
            .tag(0)
            .onAppear {
                loadPosts() // Load posts when the view appears
            }

            // Post Tab (Scan View)
            Button(action: {
                showScanView.toggle() // Show the scan view
            }) {
                VStack {
                    Text("Create New Post")
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(10)
                        .foregroundColor(.white)
                }
            }
            .tabItem {
                Image(systemName: "plus.circle.fill")
                Text("Post")
            }
            .tag(1)
            .sheet(isPresented: $showScanView) {
                ScanView(capturedImage: $capturedImage, catPosts: $catPosts, currentUsername: currentUsername)
            }

            // Profile Tab
            VStack {
                Text("User Profile")
                    .font(.largeTitle)
                    .padding()

                Button(action: {
                    isLoggedIn = false // Log out action
                }) {
                    Text("Log Out")
                        .padding()
                        .background(Color.red)
                        .cornerRadius(10)
                        .foregroundColor(.white)
                }
                .padding()
            }
            .tabItem {
                Image(systemName: "person.fill")
                Text("Profile")
            }
            .tag(2)
        }
    }

    // Save posts to UserDefaults
    private func savePosts() {
        if let encodedData = try? JSONEncoder().encode(catPosts) {
            UserDefaults.standard.set(encodedData, forKey: "catPosts")
        }
    }
    
    // Load posts from UserDefaults
    private func loadPosts() {
        if let savedData = UserDefaults.standard.data(forKey: "catPosts") {
            if let decodedPosts = try? JSONDecoder().decode([CatPost].self, from: savedData) {
                catPosts = decodedPosts
            }
        }
    }

    // Format the post time relative to the current time
    private func formatPostTime(_ postTime: Date) -> String {
        let timeInterval = Date().timeIntervalSince(postTime)
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .hour, .day]
        formatter.maximumUnitCount = 1
        formatter.unitsStyle = .full
        return formatter.string(from: timeInterval) ?? "Just now"
    }
}
