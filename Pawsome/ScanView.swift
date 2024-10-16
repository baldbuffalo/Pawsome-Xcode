import SwiftUI
import AVFoundation

// Enum to represent navigation destinations
enum NavigationDestination: Hashable {
    case form
}

struct ScanView: View {
    @Binding var capturedImage: UIImage? // Binding to capture image
    @Binding var catPosts: [CatPost] // Binding to an array of CatPost
    @State private var selectedDestination: NavigationDestination? // State to track navigation
    @State private var showImagePicker: Bool = false // State to show image picker
    @State private var imagePickerSourceType: UIImagePickerController.SourceType = .camera // Source type for ImagePicker
    @State private var showActionSheet: Bool = false // State to show action sheet

    var body: some View {
        NavigationStack {
            VStack {
                Text("Take a Picture of Your Cat")
                    .font(.headline)
                    .padding()

                Button("Open Camera") {
                    showActionSheet = true // Show the action sheet when the button is pressed
                }
                .padding()
            }
            .navigationTitle("Scan Cat")
            .actionSheet(isPresented: $showActionSheet) {
                ActionSheet(
                    title: Text("Choose Photo Option"),
                    buttons: [
                        .default(Text("Take Photo")) {
                            imagePickerSourceType = .camera
                            showImagePicker = true
                        },
                        .default(Text("Choose from Library")) {
                            imagePickerSourceType = .photoLibrary
                            showImagePicker = true
                        },
                        .cancel()
                    ]
                )
            }
            // Show ImagePicker when triggered by action sheet
            .sheet(isPresented: $showImagePicker) {
                // ImagePicker scoped inside ScanView
                ImagePicker(capturedImage: $capturedImage, sourceType: imagePickerSourceType, onImagePicked: {
                    selectedDestination = .form // Trigger navigation to FormView after picking the image
                })
            }
            // Handle navigation based on selectedDestination
            .navigationDestination(for: NavigationDestination.self) { destination in
                switch destination {
                case .form:
                    if let capturedImage = capturedImage { // Ensure image is present before navigation
                        FormView(showForm: .constant(true), catPosts: $catPosts, imageUI: capturedImage)
                    }
                }
            }
        }
    }
}

// ImagePicker struct to handle the UIImagePickerController
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    var sourceType: UIImagePickerController.SourceType
    var onImagePicked: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = context.coordinator
        imagePicker.sourceType = sourceType
        return imagePicker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.capturedImage = image // Set the captured image
                parent.onImagePicked() // Call the closure to trigger navigation
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
