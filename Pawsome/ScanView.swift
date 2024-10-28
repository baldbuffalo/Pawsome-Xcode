import SwiftUI

struct ScanView: View {
    @State private var imageUI: UIImage? // State variable for the captured image
    @State private var showingImagePicker = false
    @State private var mediaType: UIImagePickerController.SourceType? = nil // Track the selected media type
    @State private var showMediaTypeSelection = false // Control the action sheet display
    @Binding var showForm: Bool
    @Binding var navigateToHome: Bool
    @State private var catPost = CatPost() // Assuming CatPost is your Core Data entity
    var username: String // Add username as a parameter

    var body: some View {
        VStack {
            // Button to open the media type selection action sheet
            Button("Open Camera or Gallery") {
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
                    ImagePicker(sourceType: mediaType, selectedImage: $imageUI)
                }
            }

            // Display the captured image and navigate to FormView if available
            if let image = imageUI {
                NavigationLink(destination: FormView(
                    showForm: $showForm,
                    navigateToHome: $navigateToHome,
                    imageUI: image,
                    videoURL: nil,
                    username: username, // Use the passed username
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
        picker.sourceType = sourceType // Set the source type to the selected media type
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
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
