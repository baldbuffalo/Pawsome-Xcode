import SwiftUI

struct FormView: View {
    @Binding var showForm: Bool
    @Binding var navigateToHome: Bool
    var image: PlatformImage
    var username: String
    var onPostCreated: ((CatPost) -> Void)?

    @State private var catName = ""
    @State private var breed = ""
    @State private var age = ""
    @State private var location = ""
    @State private var description = ""

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

                inputField("Cat Name", $catName)
                inputField("Breed", $breed)
                inputField("Age", $age)
                inputField("Location", $location)
                inputField("Description", $description)

                Button("Post") {
                    showForm = false
                    navigateToHome = true

                    let newPost = CatPost(
                        id: nil,
                        catName: catName,
                        catBreed: breed,
                        location: location,
                        imageURL: "", // no Firebase
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
    }

    private var isFormComplete: Bool {
        !catName.isEmpty && !breed.isEmpty && !age.isEmpty && !location.isEmpty && !description.isEmpty
    }

    private func inputField(_ placeholder: String, _ binding: Binding<String>) -> some View {
        TextField(placeholder, text: binding)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding(.vertical, 5)
    }
}
