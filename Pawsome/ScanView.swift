import SwiftUI
import CoreData

struct ScanView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var imageUI: UIImage?
    @State private var showingImagePicker = false
    @State private var mediaType: UIImagePickerController.SourceType? = nil
    @State private var showMediaTypeSelection = false
    @Binding var showForm: Bool
    @Binding var navigateToHome: Bool
    @State private var catPost: CatPost?
    var username: String

    var body: some View {
        NavigationView {
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
                        ImagePicker(sourceType: mediaType, selectedImage: $imageUI, onImageSelected: { image in
                            // Create a new CatPost instance without saving
                            let newCatPost = CatPost(context: viewContext)
                            newCatPost.imageData = image.pngData()
                            newCatPost.username = username
                            catPost = newCatPost // Keep the catPost instance for later use

                            // Navigate to FormView after selecting an image
                            navigateToForm()
                        })
                    }
                }

                // Show a preview of the selected image
                if let image = imageUI {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .padding()
                } else {
                    Text("No Image Selected")
                        .padding()
                }
            }
            .navigationTitle("Scan View")
        }
    }

    private func navigateToForm() {
        // Set showForm to true to navigate to FormView
        showForm = true
    }
}

// ImagePicker Struct
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
