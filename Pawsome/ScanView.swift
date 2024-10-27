import SwiftUI
import UIKit

// Define the MediaPicker.MediaType enum
struct MediaPicker {
    enum MediaType {
        case photo
        case video
    }
}

struct ScanView: View {
    @Binding var capturedImage: UIImage?
    @Binding var videoURL: URL?
    var username: String
    var onPostCreated: (CatPost) -> Void // Callback to notify when a post is created
    @Binding var selectedImageForForm: UIImage? // New binding to send image to FormView

    @State private var isImagePickerPresented: Bool = false
    @State private var sourceType: UIImagePickerController.SourceType = .camera
    @State private var mediaType: MediaPicker.MediaType = .photo
    @State private var showMediaTypeActionSheet: Bool = false

    var body: some View {
        NavigationView {
            VStack {
                // Media Picker Button at the Top
                Button("Select Media") {
                    showMediaTypeActionSheet = true
                }
                .actionSheet(isPresented: $showMediaTypeActionSheet) {
                    ActionSheet(title: Text("Select Media Type"), buttons: [
                        .default(Text("Photo")) {
                            mediaType = .photo
                            sourceType = .camera // Open camera for taking a photo
                            isImagePickerPresented = true
                        },
                        .default(Text("Video")) {
                            mediaType = .video
                            sourceType = .camera // Set to camera for video as well
                            isImagePickerPresented = true
                        },
                        .cancel()
                    ])
                }
                .padding() // Add some padding for aesthetics

                // Present the ImagePicker
                .sheet(isPresented: $isImagePickerPresented) {
                    ImagePicker(sourceType: sourceType,
                                 selectedImage: $capturedImage,
                                 capturedVideoURL: $videoURL,
                                 mediaType: mediaType) {
                        // When the image or video is captured, create the post
                        createPost()
                        // Assign the captured image to the FormView binding
                        selectedImageForForm = capturedImage
                    }
                }

                // Display captured image
                if let image = capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .cornerRadius(10)
                        .padding()
                }

                // Optionally display the captured video URL
                if let videoURL = videoURL {
                    Text("Video URL: \(videoURL.absoluteString)")
                        .padding()
                }
                
                Spacer() // Push content up and create some space at the bottom
            }
            .navigationTitle("Media Capture")
            .navigationBarTitleDisplayMode(.inline) // Optional: adjust title display
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

        // Notify that a new post has been created
        onPostCreated(newPost)
    }
}

// ImagePicker Struct to handle image and video selection
struct ImagePicker: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType
    @Binding var selectedImage: UIImage?
    @Binding var capturedVideoURL: URL?
    var mediaType: MediaPicker.MediaType
    var completion: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        picker.mediaTypes = mediaType == .photo ? ["public.image"] : ["public.movie"]
        picker.allowsEditing = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }

            if let videoURL = info[.mediaURL] as? URL {
                parent.capturedVideoURL = videoURL
            }

            picker.dismiss(animated: true) {
                self.parent.completion()
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
