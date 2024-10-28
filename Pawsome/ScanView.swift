import SwiftUI
import CoreData

struct ScanView: View {
    @Environment(\.managedObjectContext) private var viewContext // Use environment to access Core Data context
    @State private var imageUI: UIImage? // State variable for the captured image
    @State private var showingCamera = false
    @Binding var showForm: Bool
    @Binding var navigateToHome: Bool
    @State private var catPost: CatPost?
    var username: String // Add username as a parameter

    var body: some View {
        NavigationStack {
            VStack {
                // Button to open the camera
                Button("Open Camera") {
                    showingCamera = true
                    // Initialize catPost only if it hasn't been created
                    if catPost == nil {
                        catPost = CatPost(context: viewContext)
                    }
                }
                .sheet(isPresented: $showingCamera) {
                    ImagePicker(sourceType: .camera, selectedImage: $imageUI)
                }

                // Show text if no image is captured
                if imageUI == nil {
                    Text("No image captured.")
                        .foregroundColor(.gray)
                        .padding(.top)
                }
            }
            .navigationDestination(isPresented: .constant(imageUI != nil)) {
                if let image = imageUI, let post = catPost {
                    FormView(
                        showForm: $showForm,
                        navigateToHome: $navigateToHome,
                        imageUI: image,
                        videoURL: nil,
                        username: username,
                        catPost: .constant(post),
                        onPostCreated: { post in
                            // Handle post creation if needed
                        }
                    )
                } else {
                    Text("Error: Unable to load image or post data.")
                }
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
