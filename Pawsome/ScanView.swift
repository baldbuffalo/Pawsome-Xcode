import SwiftUI
import AVKit
import PhotosUI

struct MediaPicker {
    enum MediaType: String, CaseIterable {
        case library // For selecting from the photo library
        case photo   // For capturing a photo using the camera
        case video   // For capturing a video using the camera

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
    @State private var capturedVideoURL: URL? // State variable for captured video
    var username: String
    var onPostCreated: (CatPost) -> Void

    @State private var isImagePickerPresented: Bool = false
    @State private var mediaType: MediaPicker.MediaType = .photo
    @State private var showMediaTypeActionSheet: Bool = false
    @State private var navigateToForm: Bool = false
    @State private var navigateToHome: Bool = false // New state variable for navigation

    var body: some View {
        NavigationStack {
            VStack {
                Button("Open Camera") {
                    showMediaTypeActionSheet = true
                }
                .actionSheet(isPresented: $showMediaTypeActionSheet) {
                    ActionSheet(title: Text("Select Media Type"), buttons: [
                        .default(Text(MediaPicker.MediaType.photo.displayName)) {
                            mediaType = .photo
                            isImagePickerPresented = true
                        },
                        .default(Text(MediaPicker.MediaType.video.displayName)) {
                            mediaType = .video
                            isImagePickerPresented = true
                        },
                        .default(Text(MediaPicker.MediaType.library.displayName)) {
                            mediaType = .library
                            isImagePickerPresented = true
                        },
                        .cancel()
                    ])
                }
                .sheet(isPresented: $isImagePickerPresented) {
                    ImagePicker(sourceType: sourceTypeForMediaType(mediaType),
                                 selectedImage: $capturedImage,
                                 capturedVideoURL: $capturedVideoURL, // Pass the video URL binding
                                 onImageCaptured: {
                                     navigateToForm = true // Set to true to trigger navigation
                                 },
                                 mediaType: mediaType)
                }
            }
            .navigationTitle("Camera")
            .navigationDestination(isPresented: $navigateToForm) {
                // Pass the captured image and video URL to FormView
                FormView(showForm: $navigateToForm,
                         navigateToHome: $navigateToHome, // Pass the navigateToHome binding first
                         imageUI: capturedImage,
                         videoURL: capturedVideoURL,
                         username: username,
                         onPostCreated: { catPost in
                             onPostCreated(catPost)
                         })
            }
        }
    }

    private func sourceTypeForMediaType(_ mediaType: MediaPicker.MediaType) -> UIImagePickerController.SourceType {
        switch mediaType {
        case .library:
            return .photoLibrary
        case .photo, .video:
            return .camera
        }
    }

    // Nested ImagePicker struct
    struct ImagePicker: UIViewControllerRepresentable {
        var sourceType: UIImagePickerController.SourceType
        @Binding var selectedImage: UIImage?
        @Binding var capturedVideoURL: URL? // New binding for video URL
        var onImageCaptured: () -> Void
        var mediaType: MediaPicker.MediaType

        func makeUIViewController(context: Context) -> UIImagePickerController {
            let picker = UIImagePickerController()
            picker.sourceType = sourceType
            picker.delegate = context.coordinator

            switch mediaType {
            case .photo:
                picker.mediaTypes = ["public.image"]
            case .video:
                picker.mediaTypes = ["public.movie"]
            case .library:
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
                } else if let videoURL = info[.mediaURL] as? URL {
                    parent.capturedVideoURL = videoURL // Capture the video URL
                }

                parent.onImageCaptured() // Trigger the action for navigation
                picker.dismiss(animated: true)
            }

            func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
                picker.dismiss(animated: true)
            }
        }
    }
}
