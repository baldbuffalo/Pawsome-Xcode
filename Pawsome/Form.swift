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

                Button(action: {
                    catPost.imageData = imageUI?.pngData()

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
                        .foregroundColor(catPost.name?.isEmpty == false && catPost.breed?.isEmpty == false && catPost.age?.isEmpty == false && catPost.location?.isEmpty == false && catPost.postDescription?.isEmpty == false ? .blue : .gray)
                }
                .disabled(catPost.name?.isEmpty == true || catPost.breed?.isEmpty == true || catPost.age?.isEmpty == true || catPost.location?.isEmpty == true || catPost.postDescription?.isEmpty == true)
                .padding()
            }
            .padding()
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}
