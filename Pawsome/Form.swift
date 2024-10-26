import SwiftUI
import CoreData

struct FormView: View {
    @Binding var showForm: Bool
    @Binding var navigateToHome: Bool // Binding to control navigation
    var imageUI: UIImage?
    var videoURL: URL? // Keeping this for future use, but won't be displayed
    var username: String
    var onPostCreated: (CatPost) -> Void
    @Environment(\.managedObjectContext) private var viewContext // Managed object context

    // Removed the @State properties
    @State private var catPost: CatPost // Initialize CatPost instance to hold the data

    init(showForm: Binding<Bool>, navigateToHome: Binding<Bool>, imageUI: UIImage?, videoURL: URL?, username: String, onPostCreated: @escaping (CatPost) -> Void) {
        self._showForm = showForm
        self._navigateToHome = navigateToHome
        self.imageUI = imageUI
        self.videoURL = videoURL
        self.username = username
        self.onPostCreated = onPostCreated
        
        // Initialize the CatPost object
        self._catPost = State(initialValue: CatPost(context: viewContext)) // This needs to be updated according to your context usage
        self.catPost.username = self.username // Use self.username here
    }

    var body: some View {
        ScrollView {
            VStack {
                // Display the selected image or a placeholder message
                if let image = imageUI {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                } else {
                    Text("No image captured.")
                        .foregroundColor(.gray)
                }

                // Input fields for cat information
                TextField("Cat Name", text: Binding(
                    get: { catPost.name ?? "" },
                    set: { catPost.name = $0 }
                ))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

                TextField("Breed", text: Binding(
                    get: { catPost.breed ?? "" },
                    set: { catPost.breed = $0 }
                ))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

                TextField("Age", text: Binding(
                    get: { catPost.age ?? "" },
                    set: { catPost.age = $0 }
                ))
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

                TextField("Location", text: Binding(
                    get: { catPost.location ?? "" },
                    set: { catPost.location = $0 }
                ))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

                TextField("Description", text: Binding(
                    get: { catPost.postDescription ?? "" },
                    set: { catPost.postDescription = $0 }
                ))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

                // Button to create a post
                Button(action: {
                    catPost.imageData = imageUI?.pngData() // Store image data

                    // Save the context
                    do {
                        try viewContext.save()
                        onPostCreated(catPost) // Call the post creation handler
                        // Dismiss the form and navigate to HomeView
                        showForm = false
                        navigateToHome = true
                    } catch {
                        // Handle the Core Data error
                        print("Error saving context: \(error.localizedDescription)")
                    }
                }) {
                    Text("Post")
                        .foregroundColor(catPost.name?.isEmpty == false && catPost.breed?.isEmpty == false && catPost.age?.isEmpty == false && catPost.location?.isEmpty == false && catPost.postDescription?.isEmpty == false ? .blue : .gray)
                }
                .disabled(catPost.name?.isEmpty == true || catPost.breed?.isEmpty == true || catPost.age?.isEmpty == true || catPost.location?.isEmpty == true || catPost.postDescription?.isEmpty == true) // Disable button if fields are empty
                .padding()
            }
            .padding()
        }
        .onTapGesture {
            // Dismiss the keyboard when tapping outside the text fields
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}
