import SwiftUI

struct HomeView: View {
    @Binding var isLoggedIn: Bool
    @Binding var currentUsername: String
    @Binding var profileImage: Image?

    @State private var catPosts: [CatPost] = []
    @State private var selectedImage: UIImage? = nil
    @State private var showForm: Bool = false
    @State private var showActionSheet: Bool = false // Controls the action sheet display
    @State private var mediaType: MediaType? // Enum for media type selection

    var body: some View {
        TabView {
            NavigationView {
                VStack(spacing: 0) {
                    headerView
                    postListView
                    Spacer()
                }
                .navigationTitle("Pawsome")
                .onAppear {
                    loadPosts()
                }
                .sheet(isPresented: $showForm) {
                    if let selectedImage = selectedImage {
                        FormView(showForm: $showForm, imageUI: selectedImage, username: currentUsername) { newPost in
                            catPosts.append(newPost)
                            savePosts()
                        }
                    }
                }
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }

            NavigationView {
                VStack {
                    // The content of the Post tab can go here if needed
                    Spacer()
                }
                .navigationTitle("Post")
                .onAppear {
                    // Show the action sheet when the Post tab is selected
                    showActionSheet = true
                }
                .actionSheet(isPresented: $showActionSheet) {
                    ActionSheet(
                        title: Text("Select Media"),
                        message: Text("Choose your media type"),
                        buttons: [
                            .default(Text("Take Photo")) {
                                mediaType = .photo
                                openScanView()
                            },
                            .default(Text("Take Video")) {
                                mediaType = .video
                                openScanView()
                            },
                            .default(Text("Select from Library")) {
                                mediaType = .library
                                openScanView()
                            },
                            .cancel()
                        ]
                    )
                }
            }
            .tabItem {
                Label("Post", systemImage: "camera")
            }

            NavigationView {
                ProfileView(isLoggedIn: $isLoggedIn, currentUsername: currentUsername, profileImage: $profileImage)
                    .navigationTitle("Profile")
            }
            .tabItem {
                Label("Profile", systemImage: "person")
            }
        }
        .tabViewStyle(DefaultTabViewStyle())
    }

    private func openScanView() {
        // Logic to open ScanView with the selected media type
        // This could involve presenting a new view or updating a state that ScanView observes.
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
        List(catPosts) { post in
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

    private func savePosts() {
        if let encoded = try? JSONEncoder().encode(catPosts) {
            UserDefaults.standard.set(encoded, forKey: "catPosts")
        }
    }
}

// Enum to define the media type
enum MediaType {
    case photo
    case video
    case library
}
