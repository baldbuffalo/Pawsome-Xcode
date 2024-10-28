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
                    // No additional action needed; the button state is evaluated in isPostButtonEnabled
                }

                TextField("Breed", text: Binding(
                    get: { catPost.catBreed ?? "" },
                    set: { catPost.catBreed = $0 }
                ))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: catPost.catBreed) { _ in
                    // No additional action needed; the button state is evaluated in isPostButtonEnabled
                }

                TextField("Age", text: Binding(
                    get: { catPost.catAge > 0 ? String(catPost.catAge) : "" },
                    set: { catPost.catAge = Int32($0) ?? 0 }
                ))
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: catPost.catAge) { _ in
                    // No additional action needed; the button state is evaluated in isPostButtonEnabled
                }

                TextField("Location", text: Binding(
                    get: { catPost.location ?? "" },
                    set: { catPost.location = $0 }
                ))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: catPost.location) { _ in
                    // No additional action needed; the button state is evaluated in isPostButtonEnabled
                }

                TextField("Description", text: Binding(
                    get: { catPost.postDescription ?? "" },
                    set: { catPost.postDescription = $0 }
                ))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: catPost.postDescription) { _ in
                    // No additional action needed; the button state is evaluated in isPostButtonEnabled
                }

                // Post Button
                Button(action: {
                    catPost.timestamp = Date() // Set timestamp for the post
                    onPostCreated(catPost) // Trigger the closure
                    showForm = false // Dismiss the form
                }) {
                    Text("Post")
                        .foregroundColor(isPostButtonEnabled() ? .blue : .gray) // Change color based on button state
                }
                .buttonStyle(PlainButtonStyle()) // Prevent default styling from affecting the button color
                .disabled(!isPostButtonEnabled()) // Disable the button if not all fields are filled
            }
            .padding()
            .navigationTitle("Post a Cat")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // Function to check if the post button should be enabled
    private func isPostButtonEnabled() -> Bool {
        // Ensure all fields are filled appropriately
        return !(catPost.catName?.isEmpty ?? true) &&
               !(catPost.catBreed?.isEmpty ?? true) &&
               catPost.catAge > 0 && // Ensure cat age is greater than 0
               !(catPost.location?.isEmpty ?? true) &&
               !(catPost.postDescription?.isEmpty ?? true)
    }
}
