import SwiftUI
import CoreData

struct FormView: View {
    @Binding var showForm: Bool
    @Binding var navigateToHome: Bool
    var imageUI: UIImage?
    var videoURL: URL?
    var username: String
    var onPostCreated: (CatPost) -> Void

    @Environment(\.managedObjectContext) private var viewContext // Managed object context
    @Binding var catPost: CatPost // Change this to a Binding

    init(showForm: Binding<Bool>, navigateToHome: Binding<Bool>, imageUI: UIImage?, videoURL: URL?, username: String, catPost: Binding<CatPost>, onPostCreated: @escaping (CatPost) -> Void) {
        self._showForm = showForm
        self._navigateToHome = navigateToHome
        self.imageUI = imageUI
        self.videoURL = videoURL
        self.username = username
        self.onPostCreated = onPostCreated
        self._catPost = catPost // Set binding for catPost
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Display the captured image at the top
                if let image = imageUI {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .cornerRadius(10)
                        .padding(.horizontal) // Add horizontal padding
                } else {
                    Text("No image captured.")
                        .foregroundColor(.gray)
                }

                // Form fields
                TextField("Cat Name", text: Binding(
                    get: { catPost.catName ?? "" },
                    set: { catPost.catName = $0 }
                ))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

                TextField("Breed", text: Binding(
                    get: { catPost.catBreed ?? "" },
                    set: { catPost.catBreed = $0 }
                ))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

                TextField("Age", text: Binding(
                    get: { String(catPost.catAge) }, // Convert Int32 to String directly
                    set: {
                        if let age = Int32($0), age > 0 {
                            catPost.catAge = age // Assign age directly
                        } else {
                            catPost.catAge = 0 // Assign a default value if input is invalid
                        }
                    }
                ))
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

                TextField("Location", text: Binding(
                    get: { catPost.location ?? "" },
                    set: { catPost.location = $0 }
                ))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

                TextField("Description", text: Binding(
                    get: { catPost.postDescription ?? "" },
                    set: { catPost.postDescription = $0 }
                ))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

                // Post Button
                Button(action: {
                    catPost.imageData = imageUI?.pngData() // Set image data to Core Data property
                    catPost.timestamp = Date() // Update the timestamp when posting

                    do {
                        try viewContext.save() // Save Core Data context
                        onPostCreated(catPost) // Call the onPostCreated closure to update the home view
                        showForm = false // Dismiss the form view
                        navigateToHome = true // Trigger navigation to home view
                    } catch {
                        print("Error saving post: \(error.localizedDescription)")
                    }
                }) {
                    Text("Post")
                        .foregroundColor(isPostButtonEnabled() ? .blue : .gray) // Text color only
                        .padding(.vertical, 10) // Add vertical padding for clickable area
                }
                .disabled(!isPostButtonEnabled()) // Disable button based on form validation
                .padding()
            }
            .padding(.vertical) // Add vertical padding for the entire VStack
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }

    private func isPostButtonEnabled() -> Bool {
        // Use optional binding to unwrap the optional strings
        let catName = catPost.catName ?? ""
        let catBreed = catPost.catBreed ?? ""
        let catAge = catPost.catAge
        let location = catPost.location ?? ""
        let postDescription = catPost.postDescription ?? ""

        return !catName.isEmpty && !catBreed.isEmpty && catAge > 0 && !location.isEmpty && !postDescription.isEmpty
    }
}
