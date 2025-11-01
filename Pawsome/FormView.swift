import SwiftUI

#if os(iOS)
import UIKit
#endif

struct FormView: View {
    @Binding var showForm: Bool
    @Binding var navigateToHome: Bool
    var imageUIData: Data?
    var username: String
    var onPostCreated: ((CatPost) -> Void)? // optional callback

    @State private var catName = ""
    @State private var breed = ""
    @State private var age = ""
    @State private var location = ""
    @State private var description = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                // Image preview
                if let data = imageUIData, let img = imageFromData(data) {
                    img
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .cornerRadius(10)
                } else {
                    Text("No image selected")
                        .foregroundColor(.gray)
                        .padding()
                }

                // Form fields
                inputField("Cat Name", $catName)
                inputField("Breed", $breed)

                #if os(iOS)
                inputField("Age", $age, keyboard: .numberPad)
                #else
                inputField("Age", $age)
                #endif

                inputField("Location", $location)
                inputField("Description", $description)

                // Post button
                Button("Post") {
                    showForm = false
                    navigateToHome = true

                    let newPost = CatPost(
                        id: nil,
                        catName: catName,
                        catBreed: breed,
                        location: location,
                        imageURL: "",
                        postDescription: description,
                        likes: 0,
                        comments: [],
                        catAge: Int(age) ?? 0,
                        username: username,
                        timestamp: Date(),
                        form: nil
                    )
                    onPostCreated?(newPost)
                }
                .disabled(!isFormComplete)
                .foregroundColor(isFormComplete ? .blue : .gray)
                .padding(.top)
            }
            .padding()
        }
        .onTapGesture {
            #if os(iOS)
            hideKeyboard()
            #endif
        }
    }

    // MARK: Helpers
    private var isFormComplete: Bool {
        !catName.isEmpty && !breed.isEmpty && !age.isEmpty && !location.isEmpty && !description.isEmpty
    }

    private func imageFromData(_ data: Data) -> Image? {
        #if os(iOS)
        return UIImage(data: data).map { Image(uiImage: $0) }
        #elseif os(macOS)
        return NSImage(data: data).map { Image(nsImage: $0) }
        #endif
    }

    // MARK: Input Fields
    #if os(iOS)
    private func inputField(_ placeholder: String, _ binding: Binding<String>, keyboard: UIKeyboardType? = nil) -> some View {
        TextField(placeholder, text: binding)
            .keyboardType(keyboard ?? .default)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding(.vertical, 5)
    }
    #endif

    #if os(macOS)
    private func inputField(_ placeholder: String, _ binding: Binding<String>, keyboard: Any? = nil) -> some View {
        TextField(placeholder, text: binding)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding(.vertical, 5)
    }
    #endif
}

// MARK: iOS Keyboard Dismiss Extension
#if os(iOS)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif
