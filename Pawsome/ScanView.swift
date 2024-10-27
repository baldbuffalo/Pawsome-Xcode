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

    // Changed from optional to non-optional
    @State private var newPost: CatPost?

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
                            sourceType = .camera
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

                if let image = capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .cornerRadius(10)
                        .padding()
                        .onTapGesture {
                            selectedImageForForm = image
                            isNavigatingToForm = true
                        }
                }

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
                    capturedImage = image
                    self.videoURL = videoURL
                    createPost()
                    selectedImageForForm = image
                    isNavigatingToForm = true
                }
            }
            .navigationDestination(isPresented: $isNavigatingToForm) {
                FormView(
                    showForm: .constant(false), // Pass as Binding
                    navigateToHome: .constant(false), // Pass as Binding
                    imageUI: selectedImageForForm,
                    videoURL: videoURL,
                    username: username,
                    catPost: Binding(
                        get: { newPost! }, // Assuming newPost will not be nil when you reach here
                        set: { newPost = $0 }
                    ),
                    onPostCreated: onPostCreated
                )
            }
        }
    }

    private func createPost() {
        let newPost = CatPost(context: PersistenceController.shared.container.viewContext)
        newPost.username = username
        newPost.timestamp = Date()

        if let image = capturedImage, let imageData = image.jpegData(compressionQuality: 0.8) {
            newPost.imageData = imageData
        }

        if let videoURL = videoURL {
            newPost.videoURL = videoURL.absoluteString
        }

        self.newPost = newPost
        onPostCreated(newPost)
    }
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
