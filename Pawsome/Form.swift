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
    @State private var catPost: CatPost // Hold data for a new post

    init(showForm: Binding<Bool>, navigateToHome: Binding<Bool>, imageUI: UIImage?, videoURL: URL?, username: String, onPostCreated: @escaping (CatPost) -> Void) {
        self._showForm = showForm
        self._navigateToHome = navigateToHome
        self.imageUI = imageUI
        self.videoURL = videoURL
        self.username = username
        self.onPostCreated = onPostCreated

        // Initialize a new CatPost in the managed object context
        let context = PersistenceController.shared.container.viewContext
        self._catPost = State(initialValue: CatPost(context: context))
        self.catPost.username = self.username
        self.catPost.timestamp = Date() // Set the current date as the timestamp
    }

    var body: some View {
        ScrollView {
            VStack {
                if let image = imageUI {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                } else {
                    Text("No image captured.")
                        .foregroundColor(.gray)
                }

                TextField("Cat Name", text: Binding(
                    get: { catPost.catName ?? "" },
                    set: { catPost.catName = $0 }
                ))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

                TextField("Breed", text: Binding(
                    get: { catPost.catBreed ?? "" },
                    set: { catPost.catBreed = $0 }
                ))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

                TextField("Age", text: Binding(
                    get: { String(catPost.catAge) }, // Directly convert Int32 to String
                    set: { catPost.catAge = Int32($0) ?? 0 } // Convert String to Int32, set to 0 if conversion fails
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

                Button(action: {
                    catPost.imageData = imageUI?.pngData() // Setting image data to Core Data property
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
                        .foregroundColor(catPost.catName?.isEmpty == false && catPost.catBreed?.isEmpty == false && catPost.catAge > 0 && catPost.location?.isEmpty == false && catPost.postDescription?.isEmpty == false ? .blue : .gray)
                }
                .disabled(catPost.catName?.isEmpty == true || catPost.catBreed?.isEmpty == true || catPost.catAge <= 0 || catPost.location?.isEmpty == true || catPost.postDescription?.isEmpty == true)
                .padding()
            }
            .padding()
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}
