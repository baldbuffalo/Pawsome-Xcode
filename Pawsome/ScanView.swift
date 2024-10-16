import SwiftUI
import AVKit
import PhotosUI

struct ScanView: View {
    @Binding var capturedImage: UIImage?
    var onImageCaptured: () -> Void
    var username: String
    var mediaType: MediaType?

    @State private var isImagePickerPresented: Bool = false

    var body: some View {
        VStack {
            Button("Select Media") {
                isImagePickerPresented = true
            }
            .sheet(isPresented: $isImagePickerPresented) {
                if let mediaType = mediaType {
                    ImagePicker(sourceType: mediaType == .library ? .photoLibrary : .camera, mediaType: mediaType, selectedImage: $capturedImage, onImageCaptured: {
                        onImageCaptured()
                    })
                } else {
                    // Handle case where mediaType is nil
                    Text("No media type selected.")
                }
            }
        }
        .navigationTitle("Scan View")
    }
}

// ImagePicker remains the same as previously defined.
struct ImagePicker: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType
    var mediaType: MediaType
    @Binding var selectedImage: UIImage?
    var onImageCaptured: () -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator

        switch mediaType {
        case .photo:
            picker.mediaTypes = ["public.image"]
        case .video:
            picker.mediaTypes = ["public.movie"]
        }

        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }

            parent.onImageCaptured()
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
