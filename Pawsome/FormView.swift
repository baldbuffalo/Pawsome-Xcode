import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseStorage

#if os(iOS)
import UIKit
#endif

struct FormView: View {
    @Binding var showForm: Bool
    @Binding var navigateToHome: Bool
    var imageUIData: Data?
    var videoURL: URL?
    var username: String
    var onPostCreated: ((CatPost) -> Void)? // ✅ Now passes CatPost

    @State private var catName: String = ""
    @State private var breed: String = ""
    @State private var age: String = ""
    @State private var location: String = ""
    @State private var description: String = ""

    var body: some View {
        ScrollView {
            VStack {
                if let imageData = imageUIData, let uiImage = imageFromData(imageData) {
                    uiImage
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .cornerRadius(10)
                } else {
                    Text("No image captured.")
                        .foregroundColor(.gray)
                        .padding()
                }

                inputField(placeholder: "Cat Name", text: $catName)
                inputField(placeholder: "Breed", text: $breed)

                #if os(iOS)
                inputField(placeholder: "Age", text: $age, keyboardType: .numberPad)
                #else
                inputField(placeholder: "Age", text: $age)
                #endif

                inputField(placeholder: "Location", text: $location)
                inputField(placeholder: "Description", text: $description)

                Button(action: { createPost() }) {
                    Text("Post")
                        .foregroundColor(isFormComplete ? .blue : .gray)
                }
                .disabled(!isFormComplete)
                .padding()
            }
            .padding()
        }
        .onTapGesture {
            #if os(iOS)
            hideKeyboard()
            #endif
        }
    }

    private var isFormComplete: Bool {
        !catName.isEmpty && !breed.isEmpty && !age.isEmpty && !location.isEmpty && !description.isEmpty
    }

    private func createPost() {
        guard let ageValue = Int(age) else { return }

        if let imageData = imageUIData {
            let storageRef = Storage.storage().reference().child("cat_images/\(UUID().uuidString).png")
            storageRef.putData(imageData, metadata: nil) { _, error in
                guard error == nil else { print("Error: \(error!)"); return }
                storageRef.downloadURL { url, error in
                    guard let downloadURL = url, error == nil else { print("Error: \(error!)"); return }
                    savePostData(ageValue: ageValue, imageURL: downloadURL.absoluteString)
                }
            }
        } else {
            savePostData(ageValue: ageValue, imageURL: "")
        }
    }

    private func savePostData(ageValue: Int, imageURL: String) {
        let postData: [String: Any] = [
            "username": username,
            "catName": catName,
            "catBreed": breed,
            "catAge": ageValue,
            "location": location,
            "description": description,
            "imageURL": imageURL,
            "timestamp": Timestamp(date: Date())
        ]

        Firestore.firestore().collection("posts").addDocument(data: postData) { error in
            if let error = error {
                print("Error saving post: \(error.localizedDescription)")
            } else {
                print("Post saved successfully!")
                showForm = false
                navigateToHome = true

                // ✅ Create CatPost and pass it back
                let newPost = CatPost(
                    id: nil,
                    catName: catName,
                    catBreed: breed,
                    location: location,
                    imageURL: imageURL,
                    postDescription: description,
                    likes: 0,
                    comments: [],
                    catAge: Int(ageValue),
                    username: username,
                    timestamp: Date(),
                    form: nil
                )
                onPostCreated?(newPost)
            }
        }
    }

    private func imageFromData(_ data: Data) -> Image? {
        #if os(iOS)
        if let uiImage = UIImage(data: data) { return Image(uiImage: uiImage) }
        #else
        if let nsImage = NSImage(data: data) { return Image(nsImage: nsImage) }
        #endif
        return nil
    }

    #if os(iOS)
    private func inputField(placeholder: String, text: Binding<String>, keyboardType: UIKeyboardType? = nil) -> some View {
        TextField(placeholder, text: text)
            .keyboardType(keyboardType ?? .default)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding()
    }
    #endif

    #if os(macOS)
    private func inputField(placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding()
    }
    #endif
}

#if os(iOS)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif
