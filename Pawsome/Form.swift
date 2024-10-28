import SwiftUI
import CoreData

struct FormView: View {
    @Binding var showForm: Bool
    @Binding var navigateToHome: Bool
    var imageUI: UIImage? // The selected image to display
    var videoURL: URL?
    var username: String
    var onPostCreated: (CatPost) -> Void

    @Environment(\.managedObjectContext) private var viewContext
    @Binding var catPost: CatPost

    var body: some View {
        ScrollView { // Wrap the entire content in a ScrollView
            VStack(spacing: 16) {
                // Display the selected image at the top
                if let image = imageUI {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding()
                }

                // Text fields for the form
                TextField("Cat Name", text: Binding(
                    get: { catPost.catName ?? "" },
                    set: { catPost.catName = $0 }
                ))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: catPost.catName) { _ in
                    updatePostButtonState()
                }

                TextField("Breed", text: Binding(
                    get: { catPost.catBreed ?? "" },
                    set: { catPost.catBreed = $0 }
                ))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: catPost.catBreed) { _ in
                    updatePostButtonState()
                }

                TextField("Age", text: Binding(
                    get: { catPost.catAge > 0 ? String(catPost.catAge) : "" },
                    set: { catPost.catAge = Int32($0) ?? 0 }
                ))
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: catPost.catAge) { _ in
                    updatePostButtonState()
                }

                TextField("Location", text: Binding(
                    get: { catPost.location ?? "" },
                    set: { catPost.location = $0 }
                ))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: catPost.location) { _ in
                    updatePostButtonState()
                }

                TextField("Description", text: Binding(
                    get: { catPost.postDescription ?? "" },
                    set: { catPost.postDescription = $0 }
                ))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: catPost.postDescription) { _ in
                    updatePostButtonState()
                }

                // Post Button
                Button(action: {
                    // Create a new post and call the provided closure
                    createPost()
                }) {
                    Text("Post")
                        .foregroundColor(.blue) // Always set to blue
                }
                .disabled(!isPostButtonEnabled()) // Disable the button if not all fields are filled
                .padding()
                .background(isPostButtonEnabled() ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2)) // Light background color for visibility
                .cornerRadius(8)
            }
            .padding()
            .navigationTitle("Post a Cat")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // Check if the post button should be enabled
    private func isPostButtonEnabled() -> Bool {
        return !(catPost.catName?.isEmpty ?? true) &&
               !(catPost.catBreed?.isEmpty ?? true) &&
               catPost.catAge > 0 &&
               !(catPost.location?.isEmpty ?? true) &&
               !(catPost.postDescription?.isEmpty ?? true)
    }

    // Handle post creation
    private func createPost() {
        catPost.timestamp = Date() // Set timestamp for the post
        onPostCreated(catPost) // Trigger the closure to create the post
        showForm = false // Dismiss the form
        navigateToHome = true // Navigate to the home view after posting
    }

    // Update the button state whenever a text field changes
    private func updatePostButtonState() {
        // This function is currently not necessary since `isPostButtonEnabled()` is already being checked in the button's disabled modifier.
        // However, you can call it to refresh UI if you plan to add more logic.
    }
}
