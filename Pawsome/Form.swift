import SwiftUI
import CoreData

struct FormView: View {
    @Binding var showForm: Bool
    @Binding var navigateToHome: Bool
    var imageUI: UIImage?
    var videoURL: URL?
    var username: String
    var onPostCreated: (CatPost) -> Void

    @Environment(\.managedObjectContext) private var viewContext
    @Binding var catPost: CatPost

    var body: some View {
        VStack(spacing: 16) {
            TextField("Cat Name", text: Binding(
                get: { catPost.catName ?? "" },
                set: { catPost.catName = $0 }
            ))
            .textFieldStyle(RoundedBorderTextFieldStyle())

            TextField("Breed", text: Binding(
                get: { catPost.catBreed ?? "" },
                set: { catPost.catBreed = $0 }
            ))
            .textFieldStyle(RoundedBorderTextFieldStyle())

            TextField("Age", text: Binding(
                get: { catPost.catAge > 0 ? String(catPost.catAge) : "" },
                set: { catPost.catAge = Int32($0) ?? 0 }
            ))
            .keyboardType(.numberPad)
            .textFieldStyle(RoundedBorderTextFieldStyle())

            TextField("Location", text: Binding(
                get: { catPost.location ?? "" },
                set: { catPost.location = $0 }
            ))
            .textFieldStyle(RoundedBorderTextFieldStyle())

            TextField("Description", text: Binding(
                get: { catPost.postDescription ?? "" },
                set: { catPost.postDescription = $0 }
            ))
            .textFieldStyle(RoundedBorderTextFieldStyle())

            Button(action: {
                catPost.timestamp = Date() // Set timestamp for the post
                onPostCreated(catPost) // Trigger the closure
                showForm = false // Dismiss the form
            }) {
                Text("Post")
                    .foregroundColor(isPostButtonEnabled() ? .blue : .gray)
            }
            .disabled(!isPostButtonEnabled())
        }
        .padding()
    }

    private func isPostButtonEnabled() -> Bool {
        return !(catPost.catName?.isEmpty ?? true) &&
               !(catPost.catBreed?.isEmpty ?? true) &&
               catPost.catAge > 0 &&
               !(catPost.location?.isEmpty ?? true) &&
               !(catPost.postDescription?.isEmpty ?? true)
    }
}
