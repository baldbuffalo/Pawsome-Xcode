import SwiftUI
#if os(iOS)
import UIKit
#endif
#if os(macOS)
import AppKit
#endif

struct ScanView: View {
    @Environment(\.managedObjectContext) private var viewContext
    #if os(iOS)
    @Binding var selectedImage: UIImage?
    #elseif os(macOS)
    @Binding var selectedImage: NSImage?
    #endif
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
                .padding()
                .foregroundColor(.white)
                .background(Color.blue)
                .cornerRadius(8)
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
                    if #available(macOS 13.0, *) {
                        MacMediaPicker(
                            selectedImage: $selectedImage,
                            capturedVideoURL: $capturedVideoURL,
                            mediaType: mediaType
                        )
                    } else {
                        #if os(iOS)
                        ImagePicker(
                            sourceType: sourceTypeForMediaType(mediaType),
                            selectedImage: $selectedImage,
                            capturedVideoURL: $capturedVideoURL
                        ) {
                            navigateToForm = true
                        }
                        #endif
                    }
                }
            }
            .navigationTitle("Camera")
            .navigationDestination(isPresented: $navigateToForm) {
                FormView(
                    showForm: $navigateToForm,
                    navigateToHome: $navigateToHome,
                    imageUIData: selectedImage?.pngData(),  // This works for both macOS and iOS
                    videoURL: capturedVideoURL,
                    username: username,
                    onPostCreated: { catPost in
                        // Ensure that the catPost is a valid object and not a boolean value
                        if let validCatPost = createCatPost(from: selectedImage, username: username) {
                            onPostCreated(validCatPost)
                        }
                    }
                )
            }
        }
    }

    private func sourceTypeForMediaType(_ mediaType: MediaPicker.MediaType) -> Any? {
        #if os(iOS)
        switch mediaType {
        case .library:
            return UIImagePickerController.SourceType.photoLibrary
        case .photo, .video:
            return UIImagePickerController.SourceType.camera
        }
        #elseif os(macOS)
        switch mediaType {
        case .library:
            return NSOpenPanel()
        case .photo, .video:
            return AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .unspecified).devices.first
        }
        #endif
        return nil
    }

    // Function to create a CatPost from selected image and username
    private func createCatPost(from selectedImage: Any?, username: String) -> CatPost? {
        guard let selectedImage = selectedImage else {
            return nil // Return nil if no image is selected
        }
        
        // Create and return a CatPost object. Assuming `CatPost` has an initializer that accepts image and username.
        if let uiImage = selectedImage as? UIImage {
            return CatPost(imageData: uiImage.pngData(), username: username)
        } else if let nsImage = selectedImage as? NSImage {
            return CatPost(imageData: nsImage.pngData(), username: username)
        }
        return nil
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
                defer { picker.dismiss(animated: true) }
                guard let mediaType = info[.mediaType] as? String else { return }
                if mediaType == kUTTypeImage as String, let image = info[.originalImage] as? UIImage {
                    parent.selectedImage = image
                } else if mediaType == kUTTypeMovie as String, let videoURL = info[.mediaURL] as? URL {
                    parent.capturedVideoURL = videoURL
                }
                parent.onImageCaptured()
            }

            func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
                picker.dismiss(animated: true)
            }
        }
    }
    #endif

    #if os(macOS)
    struct MacMediaPicker: View {
        @Binding var selectedImage: NSImage?
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
                            selectedImage = image
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

#if os(macOS)
extension NSImage {
    func pngData() -> Data? {
        guard let tiffData = self.tiffRepresentation else { return nil }
        let imageRep = NSBitmapImageRep(data: tiffData)
        return imageRep?.representation(using: .png, properties: [:])
    }
}
#endif
