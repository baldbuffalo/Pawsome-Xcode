import SwiftUI
#if os(iOS)
import UIKit
import MobileCoreServices
#endif
#if os(macOS)
import AppKit
import AVFoundation
import CoreMedia
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
    @State private var errorMessage: String?

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
                            mediaType: mediaType,
                            onError: { message in
                                errorMessage = message
                            }
                        )
                    } else {
                        #if os(iOS)
                        ImagePicker(
                            sourceType: sourceTypeForMediaType(mediaType),
                            selectedImage: $selectedImage,
                            capturedVideoURL: $capturedVideoURL,
                            onImageCaptured: { navigateToForm = true },
                            onError: { message in
                                errorMessage = message
                            }
                        )
                        #endif
                    }
                }

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .navigationTitle("Camera")
            .navigationDestination(isPresented: $navigateToForm) {
                FormView(
                    showForm: $navigateToForm,
                    navigateToHome: $navigateToHome,
                    imageUIData: selectedImageData(),
                    videoURL: capturedVideoURL,
                    username: username,
                    onPostCreated: { catPost in
                        if let validCatPost = createCatPost(from: selectedImage, username: username) {
                            onPostCreated(validCatPost)
                        }
                    }
                )
            }
        }
    }

    private func sourceTypeForMediaType(_ mediaType: MediaPicker.MediaType) -> UIImagePickerController.SourceType? {
        #if os(iOS)
        switch mediaType {
        case .library:
            return .photoLibrary
        case .photo, .video:
            return .camera
        }
        #elseif os(macOS)
        switch mediaType {
        case .library:
            return nil // NSOpenPanel for selecting files, no direct camera option
        case .photo, .video:
            return nil // macOS handles this separately
        }
        #endif
        return nil
    }

    private func createCatPost(from selectedImage: Any?, username: String) -> CatPost? {
        guard let selectedImage = selectedImage else {
            return nil
        }

        #if os(iOS)
        if let uiImage = selectedImage as? UIImage {
            return CatPost(imageData: uiImage.pngData(), username: username)
        }
        #elseif os(macOS)
        if let nsImage = selectedImage as? NSImage {
            return CatPost(imageData: nsImage.pngData(), username: username)
        }
        #endif
        return nil
    }

    private func selectedImageData() -> Data? {
        #if os(iOS)
        return selectedImage?.pngData()
        #elseif os(macOS)
        return selectedImage?.pngData()
        #endif
    }

    #if os(iOS)
    struct ImagePicker: UIViewControllerRepresentable {
        var sourceType: UIImagePickerController.SourceType
        @Binding var selectedImage: UIImage?
        @Binding var capturedVideoURL: URL?
        var onImageCaptured: () -> Void
        var onError: (String) -> Void

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
                guard let mediaType = info[.mediaType] as? String else {
                    parent.onError("Unsupported media type")
                    return
                }
                if mediaType == kUTTypeImage as String, let image = info[.originalImage] as? UIImage {
                    parent.selectedImage = optimizeImage(image)
                } else if mediaType == kUTTypeMovie as String, let videoURL = info[.mediaURL] as? URL {
                    parent.capturedVideoURL = videoURL
                }
                parent.onImageCaptured()
            }

            func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
                picker.dismiss(animated: true)
                parent.onError("User canceled image selection")
            }

            func optimizeImage(_ image: UIImage) -> UIImage {
                let maxSize: CGFloat = 1024
                let aspectRatio = image.size.width / image.size.height
                var newWidth: CGFloat = maxSize
                var newHeight: CGFloat = newWidth / aspectRatio
                if newHeight > maxSize {
                    newHeight = maxSize
                    newWidth = newHeight * aspectRatio
                }
                UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
                image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
                let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                return resizedImage ?? image
            }
        }
    }
    #endif

    #if os(macOS)
    struct MacMediaPicker: View {
        @Binding var selectedImage: NSImage?
        @Binding var capturedVideoURL: URL?
        var mediaType: MediaPicker.MediaType
        var onError: (String) -> Void

        var body: some View {
            Button("Choose File") {
                let panel = NSOpenPanel()
                panel.allowedFileTypes = ["public.image", "public.movie"]
                panel.allowsMultipleSelection = false
                if panel.runModal() == .OK, let url = panel.url {
                    if url.pathExtension == "jpg" || url.pathExtension == "png" {
                        if let image = NSImage(contentsOf: url) {
                            selectedImage = optimizeImage(image)
                        }
                    } else if url.pathExtension == "mov" || url.pathExtension == "mp4" {
                        capturedVideoURL = url
                    }
                } else {
                    onError("No media selected")
                }
            }
        }

        func optimizeImage(_ image: NSImage) -> NSImage? {
            let maxSize: CGFloat = 1024
            let aspectRatio = image.size.width / image.size.height
            var newWidth: CGFloat = maxSize
            var newHeight: CGFloat = newWidth / aspectRatio
            if newHeight > maxSize {
                newHeight = maxSize
                newWidth = newHeight * aspectRatio
            }
            let newSize = NSSize(width: newWidth, height: newHeight)
            let resizedImage = image.copy() as! NSImage
            resizedImage.size = newSize
            return resizedImage
        }
    }
    #endif
}

#if os(macOS)
extension NSImage {
    func pngData() -> Data? {
        guard let tiffRepresentation = self.tiffRepresentation else { return nil }
        let bitmapImageRep = NSBitmapImageRep(data: tiffRepresentation)
        return bitmapImageRep?.representation(using: .png, properties: [:])
    }
}
#endif
