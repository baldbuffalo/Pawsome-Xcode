import SwiftUI
import AVKit
import PhotosUI
import CoreData

struct ScanView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var capturedImage: UIImage?
    @State private var capturedVideoURL: URL?
    var username: String
    var onPostCreated: (CatPost) -> Void

    @State private var isImagePickerPresented: Bool = false
    @State private var mediaType: MediaPicker.MediaType = .photo
    @State private var showMediaTypeActionSheet: Bool = false
    @State private var navigateToForm: Bool = false
    @State private var navigateToHome: Bool = false

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
                    #if os(iOS)
                    ImagePicker(
                        sourceType: sourceTypeForMediaType(mediaType),
                        selectedImage: $capturedImage,
                        capturedVideoURL: $capturedVideoURL
                    ) {
                        navigateToForm = true
                    }
                    #else
                    MacMediaPicker(
                        selectedImage: $capturedImage,
                        capturedVideoURL: $capturedVideoURL,
                        mediaType: mediaType
                    )
                    #endif
                }
            }
            .navigationTitle("Camera")
            .navigationDestination(isPresented: $navigateToForm) {
                FormView(
                    showForm: $navigateToForm,
                    navigateToHome: $navigateToHome,
                    imageUIData: capturedImage?.pngData(),  // Convert UIImage to Data for upload
                    videoURL: capturedVideoURL,
                    username: username,
                    onPostCreated: { catPost in
                        onPostCreated(catPost)
                    }
                )
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

    #if os(iOS)
    struct ImagePicker: UIViewControllerRepresentable {
        var sourceType: UIImagePickerController.SourceType
        @Binding var selectedImage: UIImage?
        @Binding var capturedVideoURL: URL?
        var onImageCaptured: () -> Void

        func makeUIViewController(context: Context) -> UIImagePickerController {
            let picker = UIImagePickerController()
            picker.sourceType = sourceType
            picker.delegate = context.coordinator
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

            func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
                if let image = info[.originalImage] as? UIImage {
                    parent.selectedImage = image
                } else if let videoURL = info[.mediaURL] as? URL {
                    parent.capturedVideoURL = videoURL
                }
                parent.onImageCaptured()
                picker.dismiss(animated: true)
            }

            func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
                picker.dismiss(animated: true)
            }
        }
    }
    #endif

    #if os(macOS)
    struct MacMediaPicker: View {
        @Binding var selectedImage: UIImage?
        @Binding var capturedVideoURL: URL?
        var mediaType: MediaPicker.MediaType

        var body: some View {
            Button("Choose File") {
                let panel = NSOpenPanel()
                panel.allowedFileTypes = ["public.image", "public.movie"]
                panel.allowsMultipleSelection = false
                if panel.runModal() == .OK, let url = panel.url {
                    if url.pathExtension == "jpg" || url.pathExtension == "png" {
                        if let image = NSImage(contentsOf: url) {
                            selectedImage = UIImage(data: image.tiffRepresentation!)
                        }
                    } else if url.pathExtension == "mov" || url.pathExtension == "mp4" {
                        capturedVideoURL = url
                    }
                }
            }
        }
    }
    #endif
}

struct MediaPicker {
    enum MediaType: String, CaseIterable {
        case library
        case photo
        case video

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
