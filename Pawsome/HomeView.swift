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
                                    // No need to add post-saving logic here
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
                                // No need to add post-saving logic here
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

                    Text(post.name ?? "")
                        .font(.headline)
                    Text("Breed: \(post.breed ?? "")")
                    Text("Age: \(post.age ?? "")")
                    Text("Location: \(post.location ?? "")")
                    Text("Description: \(post.postDescription ?? "")")

                    HStack {
                        Button(action: {
                            post.likes = post.likes > 0 ? 0 : 1
                            // Removed saveContext() call
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
}
