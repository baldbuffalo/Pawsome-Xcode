import SwiftUI

#if os(iOS)
import UIKit
#else
import Cocoa
#endif

// MARK: - ImagePicker for iOS and macOS
struct ImagePickerView: View {
    @Binding var selectedImage: PlatformImage?
    var onImagePicked: (PlatformImage) -> Void

    @State private var isImagePickerPresented: Bool = false

    var body: some View {
        VStack {
            Button("Select Image") {
                isImagePickerPresented.toggle()
            }
            .sheet(isPresented: $isImagePickerPresented) {
                ImagePickerController(selectedImage: $selectedImage, onImagePicked: onImagePicked)
            }
        }
    }
}

#if os(iOS)

// MARK: - iOS ImagePickerController using UIImagePickerController
struct ImagePickerController: UIViewControllerRepresentable {
    @Binding var selectedImage: PlatformImage?
    var onImagePicked: (PlatformImage) -> Void

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var parent: ImagePickerController

        init(parent: ImagePickerController) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.selectedImage = uiImage
                parent.onImagePicked(uiImage)
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}

#else

// MARK: - macOS ImagePickerController using NSImagePicker
struct ImagePickerController: NSViewControllerRepresentable {
    @Binding var selectedImage: PlatformImage?
    var onImagePicked: (PlatformImage) -> Void

    class Coordinator: NSObject, NSOpenSavePanelDelegate {
        var parent: ImagePickerController

        init(parent: ImagePickerController) {
            self.parent = parent
        }

        func openPanel() {
            let panel = NSOpenPanel()
            panel.allowedFileTypes = ["jpg", "png", "jpeg"]
            panel.allowsMultipleSelection = false
            panel.begin { result in
                if result == .OK, let url = panel.urls.first {
                    if let image = PlatformImage(contentsOf: url) {
                        self.parent.selectedImage = image
                        self.parent.onImagePicked(image)
                    }
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    func makeNSViewController(context: Context) -> NSViewController {
        let viewController = NSViewController()
        context.coordinator.openPanel()
        return viewController
    }

    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {}
}

#endif
