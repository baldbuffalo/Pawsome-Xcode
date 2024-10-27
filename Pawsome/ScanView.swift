import SwiftUI
import UIKit

struct ScanView: View {
    @Binding var capturedImage: UIImage?
    @Binding var videoURL: URL?
    var username: String
    var onPostCreated: (CatPost) -> Void // Callback to notify when a post is created

    @State private var isImagePickerPresented: Bool = false
    @State private var sourceType: UIImagePickerController.SourceType = .camera
    @State private var mediaType: MediaPicker.MediaType = .photo
    @State private var showMediaTypeActionSheet: Bool = false

    var body: some View {
        NavigationStack {
            VStack {
                Button("Select Media") {
                    showMediaTypeActionSheet = true
                }
                .actionSheet(isPresented: $showMediaTypeActionSheet) {
                    ActionSheet(title: Text("Select Media Type"), buttons: [
                        .default(Text("Photo")) {
                            mediaType = .photo
                            sourceType = .photoLibrary // Use camera for photo if you prefer
                            isImagePickerPresented = true
                        },
                        .default(Text("Video")) {
                            mediaType = .video
                            sourceType = .camera // Use camera for video
                            isImagePickerPresented = true
                        },
                        .cancel()
                    ])
                }
                .sheet(isPresented: $isImagePickerPresented) {
                    ImagePicker(sourceType: sourceType,
                                 selectedImage: $capturedImage,
                                 capturedVideoURL: $videoURL,
                                 mediaType: mediaType) {
                        // When the image or video is captured, create the post
                        createPost()
                    }
                }

                // Display captured image
                if let image = capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .cornerRadius(10)
                }
            }
            .navigationTitle("Media Capture")
        }
    }

    private func createPost() {
        // Create the CatPost object with captured media
        let newPost = CatPost(context: PersistenceController.shared.container.viewContext)
        newPost.username = username
        newPost.timestamp = Date()

        if let image = capturedImage, let imageData = image.jpegData(compressionQuality: 0.8) {
            newPost.imageData = imageData // Store the image data
        }

        if let videoURL = videoURL {
            newPost.videoURL = videoURL.absoluteString // Store the video URL
        }

        onPostCreated(newPost) // Notify that a new post has been created
    }
}

// ImagePicker to handle media capture
struct ImagePicker: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType
    @Binding var selectedImage: UIImage?
    @Binding var capturedVideoURL: URL?
    var mediaType: MediaPicker.MediaType
    var onImageCaptured: () -> Void

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: ImagePicker

        init(parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
                parent.onImageCaptured()
            } else if let url = info[.mediaURL] as? URL {
                parent.capturedVideoURL = url
                parent.onImageCaptured()
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        picker.mediaTypes = [mediaType.rawValue] // Set the media type based on selection
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // No updates needed
    }
}

extension MediaPicker.MediaType {
    var rawValue: String {
        switch self {
        case .photo:
            return "public.image"
        case .video:
            return "public.movie"
        case .library:
            return "public.image" // or "public.movie" for both
        }
    }
}

struct MediaPicker {
    enum MediaType {
        case photo
        case video
        case library
    }
}
