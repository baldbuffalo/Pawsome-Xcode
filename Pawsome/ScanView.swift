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
    @Binding var selectedImage: UIImage?
    #elseif os(macOS)
    @Binding var selectedImage: NSImage?
    #endif

    @State private var isImagePickerPresented: Bool = false
    @State private var errorMessage: String?
    @State private var showForm: Bool = false

    var username: String = "YourUsername"
    var onPostCreated: ((CatPost) -> Void)? // ✅ expects CatPost

    @State private var useCamera: Bool = false
    @State private var showSourcePicker: Bool = false

    var body: some View {
        VStack {
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
                    isImagePickerPresented = true
                }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $isImagePickerPresented) {
                mediaPickerView()
            }

            if showForm {
                FormView(
                    showForm: $showForm,
                    navigateToHome: .constant(false),
                    imageUIData: selectedImage?.pngData(),
                    videoURL: nil,
                    username: username,
                    onPostCreated: { post in
                        onPostCreated?(post) // ✅ send actual post
                        selectedImage = nil
                        showForm = false
                    }
                )
                .frame(maxHeight: 600)
            }

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
        }
    }

    @ViewBuilder
    private func mediaPickerView() -> some View {
        #if os(iOS)
        ImagePicker(selectedImage: $selectedImage, useCamera: useCamera, onImageCaptured: {
            showForm = true
        })
        #elseif os(macOS)
        ImagePickerMac(selectedImage: $selectedImage)
        #endif
    }
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
struct ImagePickerMac: View {
    @Binding var selectedImage: NSImage?

    var body: some View {
        Button("Select Image") {
            let panel = NSOpenPanel()
            panel.allowedContentTypes = [.image]
            panel.allowsMultipleSelection = false
            if panel.runModal() == .OK,
               let url = panel.urls.first,
               let image = NSImage(contentsOf: url) {
                selectedImage = image
            }
        }
    }
}

extension NSImage {
    func pngData() -> Data? {
        guard let tiffRepresentation = self.tiffRepresentation else { return nil }
        let bitmap = NSBitmapImageRep(data: tiffRepresentation)
        return bitmap?.representation(using: .png, properties: [:])
    }
}
#endif
