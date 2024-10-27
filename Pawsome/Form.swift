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
                    get: { catPost.catAge != nil ? String(describing: catPost.catAge!) : "" }, // Safely unwrap the optional
                    set: {
                        if let age = Int32($0), age > 0 {
                            catPost.catAge = NSNumber(value: age) // Wrap in NSNumber
                        } else {
                            catPost.catAge = nil // Set to nil if input is invalid
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
                        onPostCreated(catPost)
                        showForm = false
                        navigateToHome = true
                    } catch {
                        print("Error saving post: \(error.localizedDescription)")
                    }
                }) {
                    Text("Post")
                        .foregroundColor(isPostButtonEnabled() ? .blue : .gray) // Change color based on the enabled state
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
        // Check if all fields are filled and valid
        return !(catPost.catName?.isEmpty ?? true) &&
               !(catPost.catBreed?.isEmpty ?? true) &&
               (catPost.catAge != nil) && // Ensure catAge is set and valid
               !(catPost.location?.isEmpty ?? true) &&
               !(catPost.postDescription?.isEmpty ?? true)
    }
}
