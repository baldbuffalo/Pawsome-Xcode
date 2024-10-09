import SwiftUI

struct CatPost: Identifiable {
    var id: UUID
    var name: String
    var breed: String
    var age: String
    var location: String
    var likes: Int
    var comments: [String]
    var image: UIImage? // Optional image for the cat post
}

struct FormView: View {
    @Binding var catPosts: [CatPost] // Binding to modify the posts array in HomeView
    var imageUI: UIImage? // Property to hold the optional UIImage

    @State private var catName: String = ""
    @State private var catBreed: String = ""
    @State private var catAge: String = ""
    @State private var catLocation: String = ""
    @State private var postContent: String = ""

    var body: some View {
        ScrollView {
            VStack {
                if let image = imageUI {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .cornerRadius(10)
                        .padding(.bottom, 10)
                } else {
                    Text("No Image Captured")
                        .padding(.bottom, 10)
                }

                TextField("Enter cat's name", text: $catName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.bottom, 10)

                TextField("Enter cat's breed", text: $catBreed)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.bottom, 10)

                TextField("Enter cat's age", text: $catAge)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.bottom, 10)

                TextField("Enter location", text: $catLocation)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.bottom, 10)

                TextEditor(text: $postContent)
                    .frame(height: 150)
                    .padding()
                    .border(Color.gray, width: 1)
                    .cornerRadius(5)

                Spacer()

                Button(action: {
                    submitForm()
                }) {
                    Text("Submit")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle("Create Post")
        }
    }

    private func submitForm() {
        // Create a new CatPost
        let newPost = CatPost(
            id: UUID(),
            name: catName,
            breed: catBreed,
            age: catAge,
            location: catLocation,
            likes: 0,
            comments: [],
            image: imageUI // Use the captured image
        )
        
        catPosts.append(newPost) // Append the new post to the posts array
        resetFields() // Clear the fields after submission
    }

    private func resetFields() {
        catName = ""
        catBreed = ""
        catAge = ""
        catLocation = ""
        postContent = ""
    }
}
