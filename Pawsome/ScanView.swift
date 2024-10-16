import SwiftUI
import AVFoundation

struct ScanView: View {
    @Binding var capturedImage: UIImage? // Binding to capture image
    @State private var showImagePicker: Bool = false // State to show image picker
    @State private var imagePickerSourceType: UIImagePickerController.SourceType = .camera // Source type for ImagePicker
    @State private var showActionSheet: Bool = false // State to show action sheet
    var onImageCaptured: () -> Void // Closure to handle image capture

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
                ImagePicker(capturedImage: $capturedImage, sourceType: imagePickerSourceType, onImagePicked: {
                    // Call the closure when an image is picked
                    onImageCaptured()
                })
            }
            // Handle navigation to FormView
            .navigationDestination(isPresented: Binding<Bool>(
                get: { capturedImage != nil },
                set: { if !$0 { capturedImage = nil } }
            )) {
                if let capturedImage = capturedImage {
                    FormView(showForm: .constant(true), imageUI: capturedImage) { newPost in
                        // Handle the post creation logic here
                        print("New post created with image: \(newPost)")
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
