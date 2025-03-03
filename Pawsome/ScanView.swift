#if os(macOS)
extension NSImage {
    func pngData() -> Data? {
        guard let tiffRepresentation = self.tiffRepresentation else { return nil }
        let bitmapImageRep = NSBitmapImageRep(data: tiffRepresentation)
        return bitmapImageRep?.representation(using: .png, properties: [:])
    }
}
#endif

import SwiftUI
#if os(iOS)
import UIKit
import MobileCoreServices
#endif
#if os(macOS)
import AppKit
import AVFoundation
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
    @State private var navigateToForm: Bool = false
    @State private var navigateToHome: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack {
                Button("Open Media Picker") {
                    isImagePickerPresented = true
                }
                .padding()
                .foregroundColor(.white)
                .background(Color.blue)
                .cornerRadius(8)
                .sheet(isPresented: $isImagePickerPresented) {
                    mediaPickerView()
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

    @ViewBuilder
    private func mediaPickerView() -> some View {
        #if os(iOS)
        ImagePicker(
            selectedImage: $selectedImage,
            capturedVideoURL: $capturedVideoURL,
            onImageCaptured: { navigateToForm = true },
            onError: { message in errorMessage = message }
        )
        #elseif os(macOS)
        ImagePickerMac(selectedImage: $selectedImage)
        #endif
    }

    private func createCatPost(from selectedImage: Any?, username: String) -> CatPost? {
        guard let selectedImage = selectedImage else { return nil }
        #if os(iOS)
        if let uiImage = selectedImage as? UIImage, let imageData = uiImage.pngData() {
            return CatPost(imageData: imageData, username: username)
        }
        #elseif os(macOS)
        if let nsImage = selectedImage as? NSImage, let imageData = nsImage.pngData() {
            return CatPost(imageData: imageData, username: username)
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
}

#if os(iOS)
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var capturedVideoURL: URL?
    var onImageCaptured: () -> Void
    var onError: (String) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary // Uses existing media picker
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

            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
                parent.onImageCaptured()
            } else if let videoURL = info[.mediaURL] as? URL {
                parent.capturedVideoURL = videoURL
                parent.onImageCaptured()
            } else {
                parent.onError("Unsupported media type")
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
            parent.onError("User canceled selection")
        }
    }
}
#endif

#if os(macOS)
struct ImagePickerMac: View {
    @Binding var selectedImage: NSImage?

    var body: some View {
        Button("Select Image") {
            let panel = NSOpenPanel()
            panel.allowedContentTypes = [.image]
            panel.allowsMultipleSelection = false
            if panel.runModal() == .OK, let url = panel.urls.first, let image = NSImage(contentsOf: url) {
                selectedImage = image
            }
        }
    }
}
#endif
