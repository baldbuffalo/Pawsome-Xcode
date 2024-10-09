import SwiftUI

struct HomeView: View {
    @Binding var isLoggedIn: Bool
    @State private var catPosts: [CatPost] = []
    @State private var showScanView = false
    @State private var capturedImage: UIImage? = nil
    @State private var selectedTab = 0 // Track the selected tab

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

                List(catPosts) { post in
                    VStack(alignment: .leading) {
                        if let image = post.image {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .cornerRadius(10)
                        }
                        Text(post.name).font(.headline)
                        Text("Breed: \(post.breed)").font(.subheadline)
                        Text("Age: \(post.age)").font(.subheadline)
                        Text("Location: \(post.location)").font(.subheadline)

                        HStack {
                            Button(action: {
                                if let index = catPosts.firstIndex(where: { $0.id == post.id }) {
                                    catPosts[index].likes += 1
                                }
                            }) {
                                Text("Like (\(post.likes))")
                                    .padding()
                                    .background(Color.green.opacity(0.7))
                                    .cornerRadius(5)
                                    .foregroundColor(.white)
                            }
                            Spacer()
                        }
                        .padding(.vertical)

                        ForEach(post.comments, id: \.self) { comment in
                            Text(comment)
                                .font(.subheadline)
                                .padding(.leading)
                        }

                        Button(action: {
                            // Add a comment action
                        }) {
                            Text("Add Comment")
                                .padding()
                                .background(Color.blue.opacity(0.7))
                                .cornerRadius(5)
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                }
            }
            .tabItem {
                Image(systemName: "house.fill")
                Text("Home")
            }
            .tag(0)

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
                ScanView(capturedImage: $capturedImage, catPosts: $catPosts)
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
}
