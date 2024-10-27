import SwiftUI
import UIKit

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
    var onPostCreated: (CatPost) -> Void
    @Binding var selectedImageForForm: UIImage?

    @State private var isImagePickerPresented: Bool = false
    @State private var sourceType: UIImagePickerController.SourceType = .camera
    @State private var mediaType: MediaPicker.MediaType = .photo
    @State private var showMediaTypeActionSheet: Bool = false
    @State private var isNavigatingToForm: Bool = false

    @State private var newPost: CatPost? // This is mutable

    var body: some View {
        NavigationStack {
            VStack {
                Button("Select Media") {
                    showMediaTypeActionSheet = true
                }
                .actionSheet(isPresented: $showMediaTypeActionSheet) {
                    ActionSheet(title: Text("Select Media Type"), buttons: [
                        .default(Text("Photo from Camera")) {
                            mediaType = .photo
                            sourceType = .camera
                            isImagePickerPresented = true
                        },
                        .default(Text("Photo from Gallery")) {
                            mediaType = .photo
                            sourceType = .photoLibrary
                            isImagePickerPresented = true
                        },
                        .default(Text("Video")) {
                            mediaType = .video
                            sourceType = .camera
                            isImagePickerPresented = true
                        },
                        .cancel()
                    ])
                }
                .padding()

                // Removed the Image display section

                if let videoURL = videoURL {
                    Text("Video URL: \(videoURL.absoluteString)")
                        .padding()
                }

                Spacer()
            }
            .navigationTitle("Media Capture")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isImagePickerPresented) {
                ImagePickerView(sourceType: sourceType, mediaType: mediaType) { image, videoURL in
                    // Handle the selected image and video URL
                    capturedImage = image
                    self.videoURL = videoURL
                    
                    // Send the selected image to the form
                    if let selectedImage = image {
                        selectedImageForForm = selectedImage
                    }

                    // Navigate to the form
                    isNavigatingToForm = true
                }
            }
            .navigationDestination(isPresented: $isNavigatingToForm) {
                // Safely unwrap newPost
                if let newPost = newPost {
                    FormView(
                        showForm: .constant(false),
                        navigateToHome: .constant(false),
                        imageUI: selectedImageForForm,
                        videoURL: videoURL,
                        username: username,
                        catPost: Binding(
                            get: { newPost },
                            set: { self.newPost = $0 }
                        ),
                        onPostCreated: onPostCreated
                    )
                } else {
                    // Handle the case where newPost is nil
                    // You might want to show an alert or navigate back
                }
            }
        }
    }

    // The createPost function is no longer needed if we're not posting the image
}

// Combined ImagePicker functionality
struct ImagePickerView: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType
    var mediaType: MediaPicker.MediaType
    var onImagePicked: (UIImage?, URL?) -> Void

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
        var parent: ImagePickerView

        init(_ parent: ImagePickerView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage
            let videoURL = info[.mediaURL] as? URL
            
            parent.onImagePicked(image, videoURL)

            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
