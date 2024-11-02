import SwiftUI
import CoreData

struct FormView: View {
    @Binding var showForm: Bool
    @Binding var navigateToHome: Bool
    var imageUI: UIImage?
    var videoURL: URL?
    var username: String
    @ObservedObject var dataManager: DataManager // Using DataManager here

    @State private var catName: String = ""
    @State private var breed: String = ""
    @State private var age: String = ""
    @State private var location: String = ""
    @State private var description: String = ""

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

                inputField(placeholder: "Cat Name", text: $catName)
                inputField(placeholder: "Breed", text: $breed)
                inputField(placeholder: "Age", text: $age, keyboardType: .numberPad)
                inputField(placeholder: "Location", text: $location)
                inputField(placeholder: "Description", text: $description)

                Button(action: {
                    createPost()
                }) {
                    Text("Post")
                        .foregroundColor(catName.isEmpty || breed.isEmpty || age.isEmpty || location.isEmpty || description.isEmpty ? .gray : .blue)
                }
                .disabled(catName.isEmpty || breed.isEmpty || age.isEmpty || location.isEmpty || description.isEmpty)
                .padding()
            }
            .padding()
        }
        .onTapGesture {
            hideKeyboard()
        }
    }

    private func createPost() {
        guard let ageValue = Int32(age) else { return }
        dataManager.addPost(username: username, catName: catName, catBreed: breed, catAge: ageValue, location: location, content: description, imageData: imageUI?.pngData())
        showForm = false
        navigateToHome = true
    }
}

// Helper function for text fields
private func inputField(placeholder: String, text: Binding<String>, keyboardType: UIKeyboardType = .default) -> some View {
    TextField(placeholder, text: text)
        .keyboardType(keyboardType)
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .padding()
}

// Extension to hide the keyboard
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
