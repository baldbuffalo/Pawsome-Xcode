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
    
    @State private var isSubmitting: Bool = false // State to manage loading state
    
    @Environment(\.presentationMode) var presentationMode // For dismissing the form view
    
    var body: some View {
        ZStack {
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
            
            // Loading overlay
            if isSubmitting {
                Color.black.opacity(0.5) // Semi-transparent background
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    ProgressView() // Loading circle
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                        .padding(.bottom, 20)
                    
                    Text("Creating...")
                        .foregroundColor(.white)
                        .font(.headline)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity) // Take full screen
                .background(Color.black.opacity(0.5)) // Overlay
            }
        }
    }
    
    private func submitForm() {
        // Show loading indicator
        isSubmitting = true
        
        // Simulate a network request delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
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
            
            // Stop the loading animation and go to `ContentView`
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                isSubmitting = false // Hide the loading circle
                presentationMode.wrappedValue.dismiss() // Close the form screen and go back to Home/ContentView
            }
        }
    }
    
    private func resetFields() {
        catName = ""
        catBreed = ""
        catAge = ""
        catLocation = ""
        postContent = ""
    }
}
