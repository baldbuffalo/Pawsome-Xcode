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

    // New state bindings for FormView
    @State private var showForm: Bool = false
    @State private var navigateToHome: Bool = false

    var body: some View {
        NavigationView {
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

                .sheet(isPresented: $isImagePickerPresented) {
                    ImagePicker(sourceType: sourceType,
                                 selectedImage: $capturedImage,
                                 capturedVideoURL: $videoURL,
                                 mediaType: mediaType) {
                        createPost()
                        selectedImageForForm = capturedImage
                        isNavigatingToForm = true
                    }
                }

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
            .background(
                NavigationLink(destination: FormView(
                    showForm: $showForm, // Pass as Binding
                    navigateToHome: $navigateToHome, // Pass as Binding
                    imageUI: selectedImageForForm,
                    videoURL: videoURL,
                    username: username,
                    onPostCreated: onPostCreated
                ),
                isActive: $isNavigatingToForm) {
                    EmptyView()
                }
            )
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

        onPostCreated(newPost)
    }
}

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
