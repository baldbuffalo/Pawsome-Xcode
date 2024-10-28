import SwiftUI
<<<<<<< HEAD
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
=======
import CoreData

struct ScanView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var selectedImage: UIImage? // Binding to hold the selected image
    @Binding var showForm: Bool // Binding to control form visibility
    var username: String
    
    @State private var showingImagePicker = false // State to show the image picker
    @State private var mediaType: UIImagePickerController.SourceType? = nil // State for media type selection
    @State private var showMediaTypeSelection = false // State for media type selection action sheet

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Button to initiate image selection
                Button("Select Image") {
                    showMediaTypeSelection = true
                }
                .actionSheet(isPresented: $showMediaTypeSelection) {
                    ActionSheet(
                        title: Text("Choose Media Type"),
                        buttons: [
                            .default(Text("Camera")) {
                                mediaType = .camera
                                showingImagePicker = true
                            },
                            .default(Text("Photo Library")) {
                                mediaType = .photoLibrary
                                showingImagePicker = true
                            },
                            .cancel()
                        ]
                    )
                }
                .sheet(isPresented: $showingImagePicker) {
                    if let mediaType = mediaType {
                        ImagePicker(sourceType: mediaType, selectedImage: $selectedImage) { image in
                            navigateToForm() // Navigate to FormView after image selection
                        }
                    }
                }

                // Preview selected image
                if let selectedImage = selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .cornerRadius(10)
                        .padding()
                }

                Spacer()
            }
            .navigationTitle("Scan View")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showForm) {
                // Pass the selected image to FormView
                FormView(
                    showForm: $showForm,
                    currentUsername: username,
                    onPostCreated: { _ in },
                    selectedImage: $selectedImage // Pass the selected image as a binding
                )
>>>>>>> 5eef0f8bd39986f9f45e071df446cc125709c1b6
            }
        }
    }

<<<<<<< HEAD
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
=======
    private func navigateToForm() {
        showForm = true
    }
}

// ImagePicker Struct for Image Selection
struct ImagePicker: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType
    @Binding var selectedImage: UIImage?
    var onImageSelected: (UIImage) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
                parent.onImageSelected(image)
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
>>>>>>> 5eef0f8bd39986f9f45e071df446cc125709c1b6
        }
    }
}
