import SwiftUI

struct HomeView: View {
    @State private var catPosts: [CatPost] = [] // Array to hold the posts
    @State private var showPostForm = false // To show the post form

    var body: some View {
        VStack(spacing: 0) {  // Set spacing to 0 to remove extra gaps
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
                            // Increment the like count
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

                    // Comment section
                    ForEach(post.comments, id: \.self) { comment in
                        Text(comment)
                            .font(.subheadline)
                            .padding(.leading)
                    }

                    // Add comment button
                    Button(action: {
                        // Add a comment (you'll need to implement a way to enter comments)
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

            Button(action: {
                showPostForm.toggle() // Show the post form
            }) {
                Text("Create New Post")
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(10)
                    .foregroundColor(.white)
            }
            .padding()
        }
        .sheet(isPresented: $showPostForm) {
            Form(catPosts: $catPosts) // Pass the posts array to PostView
        }
    }
}
