import SwiftUI
import CoreData

struct ScanView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var selectedImage: UIImage? // Binding to hold the selected image
    @Binding var showForm: Bool // Binding to control form visibility
    var username: String
    
    @State private var showingImagePicker = false // State to show the image picker
    @State private var mediaType: UIImagePickerController.SourceType? = nil // State for media type selection
    @State private var showMediaTypeSelection = false // State for media type selection action sheet

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Button to initiate image selection
                Button("Select Image") {
                    showMediaTypeSelection = true
                }
                .actionSheet(isPresented: $showMediaTypeSelection) {
                    ActionSheet(
                        title: Text("Choose Media Type"),
                        buttons: [
                            .default(Text("Camera")) {
                                mediaType = .camera
                                showingImagePicker = true
                            },
                            .default(Text("Photo Library")) {
                                mediaType = .photoLibrary
                                showingImagePicker = true
                            },
                            .cancel()
                        ]
                    )
                }
                .sheet(isPresented: $showingImagePicker) {
                    if let mediaType = mediaType {
                        ImagePicker(sourceType: mediaType, selectedImage: $selectedImage) { image in
                            navigateToForm() // Navigate to FormView after image selection
                        }
                    }
                }
            }
            .navigationTitle("Scan View")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showForm) {
                // Pass all required arguments to FormView
                FormView(
                    showForm: $showForm,
                    navigateToHome: .constant(false), // Assuming you want to pass a constant here
                    imageUI: selectedImage,
                    username: username,
                    onPostCreated: { _ in },
                    catPost: .constant(CatPost(context: viewContext))
                )
            }
        }
    }

    private func navigateToForm() {
        showForm = true
    }
}

// ImagePicker Struct for Image Selection
struct ImagePicker: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType
    @Binding var selectedImage: UIImage?
    var onImageSelected: (UIImage) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
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
                parent.onImageSelected(image)
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
