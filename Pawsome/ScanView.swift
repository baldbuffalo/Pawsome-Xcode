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
    #if os(iOS)
    @State private var selectedImage: UIImage?
    #elseif os(macOS)
    @State private var selectedImage: NSImage?
    #endif

    @State private var isImagePickerPresented = false
    @State private var showForm = false
    @State private var showSourcePicker = false

    var username: String = "YourUsername"
    var onPostCreated: ((CatPost) -> Void)?

    @State private var useCamera: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Button("Choose Image") {
                    showSourcePicker = true
                }
                .padding()
                .foregroundColor(.white)
                .background(Color.blue)
                .cornerRadius(8)
                .confirmationDialog("Select Image Source", isPresented: $showSourcePicker, titleVisibility: .visible) {
                    #if os(iOS)
                    Button("Open Camera") {
                        useCamera = true
                        isImagePickerPresented = true
                    }
                    #endif
                    Button("Open Files") {
                        useCamera = false
                        #if os(macOS)
                        openMacFiles()
                        #else
                        isImagePickerPresented = true
                        #endif
                    }
                    Button("Cancel", role: .cancel) {}
                }
            }
            .padding()
            .sheet(isPresented: $isImagePickerPresented) {
                #if os(iOS)
                ImagePicker(selectedImage: $selectedImage, useCamera: useCamera) {
                    showForm = true
                }
                #endif
            }
            .navigationDestination(isPresented: $showForm) {
                FormView(
                    showForm: $showForm,
                    navigateToHome: .constant(false),
                    imageUIData: getImageData(),
                    username: username,
                    onPostCreated: onPostCreated
                )
            }
        }
    }

    private func getImageData() -> Data? {
        #if os(iOS)
        return selectedImage?.pngData()
        #elseif os(macOS)
        return selectedImage?.pngData()
        #endif
    }

    #if os(macOS)
    private func openMacFiles() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.urls.first, let image = NSImage(contentsOf: url) {
            selectedImage = image
            showForm = true
        }
    }
    #endif
}

#if os(iOS)
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    var useCamera: Bool
    var onImageCaptured: () -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = useCamera && UIImagePickerController.isSourceTypeAvailable(.camera)
            ? .camera
            : .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            defer { picker.dismiss(animated: true) }
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
                parent.onImageCaptured()
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
#endif

#if os(macOS)
extension NSImage {
    func pngData() -> Data? {
        guard let tiff = tiffRepresentation else { return nil }
        let bitmap = NSBitmapImageRep(data: tiff)
        return bitmap?.representation(using: .png, properties: [:])
    }
}
#endif
