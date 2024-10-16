import SwiftUI
import AVKit
import PhotosUI

// Define a struct to namespace the MediaType enum
struct MediaPicker {
    enum MediaType: String, CaseIterable {
        case library // For selecting from the photo library
        case photo   // For capturing a photo using the camera
        case video   // For capturing a video using the camera

        // Providing a display name for the picker
        var displayName: String {
            switch self {
            case .library:
                return "Photo Library"
            case .photo:
                return "Camera (Photo)"
            case .video:
                return "Camera (Video)"
            }
        }
    }
}

struct ScanView: View {
    @Binding var capturedImage: UIImage?
    var onImageCaptured: () -> Void
    var username: String

    @State private var isImagePickerPresented: Bool = false
    @State private var mediaType: MediaPicker.MediaType = .photo // Default media type

    var body: some View {
        VStack {
            // Picker to select media type
            Picker("Select Media Type", selection: $mediaType) {
                ForEach(MediaPicker.MediaType.allCases, id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            Button("Select Media") {
                isImagePickerPresented = true
            }
            .sheet(isPresented: $isImagePickerPresented) {
                ImagePicker(sourceType: sourceTypeForMediaType(mediaType),
                             selectedImage: $capturedImage,
                             onImageCaptured: {
                                 onImageCaptured()
                             },
                             mediaType: mediaType) // Pass the mediaType here
            }
        }
        .navigationTitle("Scan View")
    }

    // Function to determine the source type based on MediaType
    private func sourceTypeForMediaType(_ mediaType: MediaPicker.MediaType) -> UIImagePickerController.SourceType {
        switch mediaType {
        case .library:
            return .photoLibrary
        case .photo, .video:
            return .camera // Both photo and video use the camera
        }
    }
}

// ImagePicker struct
struct ImagePicker: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType
    @Binding var selectedImage: UIImage?
    var onImageCaptured: () -> Void
    var mediaType: MediaPicker.MediaType // Use the namespaced enum

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator

        // Set media types based on mediaType
        switch mediaType {
        case .photo:
            picker.mediaTypes = ["public.image"]
        case .video:
            picker.mediaTypes = ["public.movie"]
        case .library:
            // Handle both images and videos if needed
            picker.mediaTypes = ["public.image", "public.movie"]
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
