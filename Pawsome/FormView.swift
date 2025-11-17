import SwiftUI

struct FormView: View {
    @Binding var showForm: Bool
    @Binding var navigateToHome: Bool
    var image: PlatformImage
    var username: String
    var onPostCreated: (() -> Void)?

    @State private var name = ""
    @State private var description = ""
    @State private var imageURL = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                #if os(iOS)
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .cornerRadius(10)
                #elseif os(macOS)
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .cornerRadius(10)
                #endif

                inputField("Cat Name", $name)
                inputField("Description", $description)
                inputField("Image URL (optional)", $imageURL)

                Button("Post 🐾") {
                    // For testing: just reset and call closure
                    name = ""
                    description = ""
                    imageURL = ""
                    showForm = false
                    navigateToHome = true
                    onPostCreated?()
                }
                .disabled(!isFormComplete)
                .foregroundColor(isFormComplete ? .blue : .gray)
                .padding(.top)
            }
            .padding()
        }
    }

    private var isFormComplete: Bool {
        !name.isEmpty && !description.isEmpty
    }

    private func inputField(_ placeholder: String, _ binding: Binding<String>) -> some View {
        TextField(placeholder, text: binding)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding(.vertical, 5)
    }
}
