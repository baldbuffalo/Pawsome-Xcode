import SwiftUI

struct ScanView: View {
    @State private var imageUI: UIImage? // State variable for the captured image
    @State private var showingCamera = false
    @Binding var showForm: Bool
    @Binding var navigateToHome: Bool
    @State private var catPost = CatPost() // Assuming CatPost is your Core Data entity
    var username: String // Add username as a parameter

    var body: some View {
        VStack {
            // Button to open the camera
            Button("Open Camera") {
                showingCamera = true
            }
            .sheet(isPresented: $showingCamera) {
                ImagePicker(sourceType: .camera, selectedImage: $imageUI)
            }

            // Navigation to FormView once an image is captured
            if let image = imageUI {
                NavigationLink(
                    destination: FormView(
                        showForm: $showForm,
                        navigateToHome: $navigateToHome,
                        imageUI: image,
                        videoURL: nil,
                        username: username, // Use the passed username
                        catPost: .constant(catPost),
                        onPostCreated: { post in
                            // Handle post creation if needed
                        }
                    ),
                    isActive: .constant(true), // Automatically activate the link
                    label: { EmptyView() } // No visual element here
                )
            } else {
                Text("No image captured.")
                    .foregroundColor(.gray)
                    .padding(.top)
            }
        }
    }
}

// ImagePicker Struct
struct ImagePicker: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType
    @Binding var selectedImage: UIImage?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType // Set to camera
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
