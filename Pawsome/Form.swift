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
    var onPostCreated: ((Bool) -> Void)?
    
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
                    
                    let postData: [String: Any] = [
                        "username": username,
                        "catName": catName,
                        "catBreed": breed,
                        "catAge": ageValue,
                        "location": location,
                        "description": description,
                        "imageURL": downloadURL.absoluteString,
                        "timestamp": Timestamp(date: Date())
                    ]
                    
                    Firestore.firestore().collection("posts").addDocument(data: postData) { error in
                        if let error = error {
                            print("Error saving post: \(error.localizedDescription)")
                        } else {
                            print("Post saved successfully!")
                            showForm = false
                            navigateToHome = true
                            onPostCreated?(true) // Call the onPostCreated closure
                        }
                    }
                }
            }
        } else {
            savePostData(ageValue: ageValue, imageURL: "")
        }
    }
    
    private func savePostData(ageValue: Int32, imageURL: String) {
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
                onPostCreated?(true) // Call the onPostCreated closure
            }
        }
    }
    
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
    
    // iOS-specific inputField
#if os(iOS)
    private func inputField(placeholder: String, text: Binding<String>, keyboardType: UIKeyboardType? = nil) -> some View {
        let actualKeyboardType = keyboardType ?? .default
        return TextField(placeholder, text: text)
            .keyboardType(actualKeyboardType)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding()
    }
#endif
    
    // macOS-specific inputField (no UIKeyboardType here)
#if os(macOS)
    private func inputField(placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .textFieldStyle(RoundedBorderTextFieldStyle()) // Standard macOS style
            .padding() // Add padding for spacing
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
