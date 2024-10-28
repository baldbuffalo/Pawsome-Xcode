import SwiftUI
import CoreData

struct ScanView: View {
    @Environment(\.managedObjectContext) private var viewContext // Access the managed object context
    @State private var imageUI: UIImage? // State variable for the captured image
    @State private var showingImagePicker = false
    @State private var mediaType: UIImagePickerController.SourceType? = nil // Track the selected media type
    @State private var showMediaTypeSelection = false // Control the action sheet display
    @Binding var showForm: Bool
    @Binding var navigateToHome: Bool
    @State private var catPost: CatPost? // Optional CatPost instance
    var username: String // Add username as a parameter

    var body: some View {
        VStack {
            // Button to open the media type selection action sheet
            Button("Open Camera") {
                showMediaTypeSelection = true // Show action sheet
            }
            .actionSheet(isPresented: $showMediaTypeSelection) {
                ActionSheet(
                    title: Text("Choose Media Type"),
                    buttons: [
                        .default(Text("Camera")) {
                            mediaType = .camera
                            showingImagePicker = true
                        },
                        .default(Text("Gallery")) {
                            mediaType = .photoLibrary
                            showingImagePicker = true
                        },
                        .cancel()
                    ]
                )
            }
            .sheet(isPresented: $showingImagePicker) {
                if let mediaType = mediaType {
                    ImagePicker(sourceType: mediaType, selectedImage: $imageUI, onImageSelected: { image in
                        // Create a new CatPost instance and set its properties
                        let newCatPost = CatPost(context: viewContext)
                        newCatPost.imageData = image.pngData() // Set image data
                        newCatPost.username = username // Set username or any other properties as needed
                        catPost = newCatPost // Assign it to state variable if needed
                        navigateToForm() // Navigate to FormView
                    })
                }
            }
        }
    }

    private func navigateToForm() {
        // Navigate to FormView
        showForm = true
        // Additional logic to navigate can be placed here if needed
    }
}

// ImagePicker Struct (remains unchanged)
struct ImagePicker: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType
    @Binding var selectedImage: UIImage?
    var onImageSelected: (UIImage) -> Void // Callback to handle selected image

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        picker.mediaTypes = ["public.image"] // Set to only pick images
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
                parent.onImageSelected(image) // Call the callback with the selected image
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
