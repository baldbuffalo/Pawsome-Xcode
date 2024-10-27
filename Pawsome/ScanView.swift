import SwiftUI

struct ScanView: View {
    @State private var imageUI: UIImage? // State variable for the selected image
    @State private var showingImagePicker = false
    @Binding var showForm: Bool
    @Binding var navigateToHome: Bool
    @State private var catPost = CatPost() // Assuming CatPost is your Core Data entity

    var body: some View {
        VStack {
            // Button to show image picker
            Button("Choose Image from Gallery") {
                showingImagePicker = true
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImage: $imageUI)
            }

            // Display the selected image
            if let image = imageUI {
                NavigationLink(destination: FormView(
                    showForm: $showForm,
                    navigateToHome: $navigateToHome,
                    imageUI: image,
                    videoURL: nil,
                    username: "Username", // Replace with the actual username
                    catPost: .constant(catPost),
                    onPostCreated: { post in
                        // Handle post creation if needed
                    }
                )) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .cornerRadius(10)
                }
                .padding(.top)
            } else {
                Text("No image selected.")
                    .foregroundColor(.gray)
                    .padding(.top)
            }
            
            // Placeholder for scan functionality
            // Here, you can add your scanning logic or button.
            Button("Scan Image") {
                // Implement scanning functionality here
                // For example, you could directly capture the image from the camera
            }
        }
        .navigationTitle("Scan or Select Image")
        .padding()
    }
}

// ImagePicker Struct
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
