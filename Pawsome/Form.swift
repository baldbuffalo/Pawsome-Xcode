import SwiftUI

struct Form: View {
    var imageUI: UIImage?

    // State variables to hold user input
    @State private var catName: String = ""
    @State private var catBreed: String = ""
    @State private var catAge: String = ""
    @State private var catLocation: String = ""

    // State variable to control the visibility of the text area
    @State private var isEditingPost: Bool = false
    @State private var postContent: String = "" // Content of the post

    var body: some View {
        ScrollView { // Wrap content in a ScrollView
            VStack {
                if let image = imageUI {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300, height: 300)
                        .padding(.bottom, 20)
                } else {
                    Text("No image available")
                        .padding(.bottom, 20)
                }

                // Cat Name input field
                TextField("Enter cat's name", text: $catName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.bottom, 10)
                    .onChange(of: catName) { newValue in
                        // Validation can be done here if necessary
                    }

                // Cat Breed input field
                TextField("Enter cat's breed", text: $catBreed)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.bottom, 10)
                    .onChange(of: catBreed) { newValue in
                        // Validation can be done here if necessary
                    }

                // Cat Age input field
                TextField("Enter cat's age", text: $catAge)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.bottom, 10)
                    .onChange(of: catAge) { newValue in
                        // Validation can be done here if necessary
                    }

                // Location input field
                TextField("Enter location", text: $catLocation)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.bottom, 20)
                    .onChange(of: catLocation) { newValue in
                        // Validation can be done here if necessary
                    }

                // Big box for editing post
                Text("Edit Post")
                    .font(.largeTitle) // Large font for emphasis
                    .padding()
                    .frame(maxWidth: .infinity) // Take full width
                    .background(Color.gray.opacity(0.2)) // Light gray background
                    .cornerRadius(10) // Rounded corners
                    .padding(.bottom, 20) // Spacing below the box
                    .onTapGesture {
                        isEditingPost.toggle() // Toggle the editing mode on tap
                    }

                // Conditional TextEditor for editing the post content
                if isEditingPost {
                    TextEditor(text: $postContent)
                        .frame(height: 150) // Set height for the text editor
                        .padding()
                        .border(Color.gray, width: 1) // Border around the text editor
                        .cornerRadius(5) // Rounded corners
                        .padding(.bottom, 20) // Spacing below the editor
                        .onChange(of: postContent) { newValue in
                            // Validation can be done here if necessary
                        }
                }

                Spacer()

                // Submit Button
                Button(action: {
                    // Handle form submission
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
            .navigationTitle("Cat Information")
        } // End of ScrollView
    }

    // Function to dismiss keyboard
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    // Function to handle form submission
    private func submitForm() {
        // Dismiss the keyboard when Submit is clicked
        dismissKeyboard()

        DispatchQueue.main.async {
            // Debugging print statements
            print("Attempting to submit form with the following details:")
            print("Cat Name: \(catName)")
            print("Cat Breed: \(catBreed)")
            print("Cat Age: \(catAge)")
            print("Location: \(catLocation)")
            print("Post Content: \(postContent)") // Print the content of the post
            
            // You can add additional logic here to save or handle the input data
            // E.g., sending the data to a backend or saving locally
        }
    }
}
