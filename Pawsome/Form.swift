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
    var onPostCreated: (() -> Void)?

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

                Button(action: {
                    createPost()
                }) {
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
        return !catName.isEmpty && !breed.isEmpty && !age.isEmpty && !location.isEmpty && !description.isEmpty
    }

    private func createPost() {
        guard let ageValue = Int32(age) else { return }

        if let imageData = imageUIData {
            let storageRef = Storage.storage().reference().child("cat_images/\(UUID().uuidString).png")

            storageRef.putData(imageData, metadata: nil) { metadata, error in
                guard error == nil else {
                    print("Error uploading image: \(error!.localizedDescription)")
                    return
                }

                storageRef.downloadURL { url, error in
                    guard let downloadURL = url, error == nil else {
                        print("Error getting download URL: \(error!.localizedDescription)")
                        return
                    }

                    // Save the post data in Firestore
                    Firestore.firestore().collection("posts").addDocument(data: [
                        "username": username,
                        "catName": catName,
                        "catBreed": breed,
                        "catAge": ageValue,
                        "location": location,
                        "description": description,
                        "imageURL": downloadURL.absoluteString,
                        "timestamp": Timestamp(date: Date())
                    ]) { error in
                        if let error = error {
                            print("Error saving post: \(error.localizedDescription)")
                        } else {
                            print("Post saved successfully!")
                            showForm = false
                            navigateToHome = true
                        }
                    }
                }
            }
        } else {
            // Save the post data without an image
            Firestore.firestore().collection("posts").addDocument(data: [
                "username": username,
                "catName": catName,
                "catBreed": breed,
                "catAge": Int32(age)!,
                "location": location,
                "description": description,
                "imageURL": "",
                "timestamp": Timestamp(date: Date())
            ]) { error in
                if let error = error {
                    print("Error saving post: \(error.localizedDescription)")
                } else {
                    print("Post saved successfully!")
                    showForm = false
                    navigateToHome = true
                }
            }
        }

        // Call the onPostCreated closure if it's set
        onPostCreated?()
    }

    // Helper function to convert image data to a SwiftUI Image
    private func imageFromData(_ data: Data) -> Image? {
        #if os(iOS)
        if let uiImage = UIImage(data: data) {
            return Image(uiImage: uiImage)
        }
        #else
        if let nsImage = NSImage(data: data) {
            return Image(nsImage: nsImage)
        }
        #endif
        return nil
    }

    #if os(iOS)
    // This inputField method is now scoped within the iOS block
    private func inputField(placeholder: String, text: Binding<String>, keyboardType: UIKeyboardType? = nil) -> some View {
        if let keyboardType = keyboardType {
            return AnyView(TextField(placeholder, text: text)
                            .keyboardType(keyboardType)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding())
        } else {
            return AnyView(TextField(placeholder, text: text)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding())
        }
    }

    // Helper function to hide keyboard on tap
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    #endif
}
