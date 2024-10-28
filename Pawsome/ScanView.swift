import SwiftUI
import CoreData

struct ScanView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var imageUI: UIImage?
    @State private var showingImagePicker = false
    @State private var mediaType: UIImagePickerController.SourceType? = nil
    @State private var showMediaTypeSelection = false
    @Binding var showForm: Bool
    @Binding var selectedImage: UIImage? // Binding to hold the selected image
    var username: String

    var body: some View {
        NavigationStack {
            VStack {
                Button("Open Camera") {
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
                        ImagePicker(sourceType: mediaType, selectedImage: $imageUI) { image in
                            // Set the selected image
                            selectedImage = image
                            navigateToForm()
                        }
                    }
                }
            }
            .navigationTitle("Scan View")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showForm) {
                FormView(
                    showForm: $showForm,
                    navigateToHome: .constant(false),
                    imageUI: selectedImage,
                    videoURL: nil,
                    username: username,
                    catPost: .constant(CatPost(context: viewContext)), // Ensure CatPost is initialized with the context
                    onPostCreated: { _ in }
                )
            }
        }
    }

    private func navigateToForm() {
        // Set showForm to true to navigate to FormView
        showForm = true
    }
}

// Integrated ImagePicker
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
        picker.mediaTypes = ["public.image"]
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
