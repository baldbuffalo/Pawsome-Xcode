import SwiftUI

#if os(iOS)
import UIKit

struct ImagePickerView: UIViewControllerRepresentable {
    @Binding var selectedImage: PlatformImage?
    var onImagePicked: ((PlatformImage) -> Void)? // ✅ callback

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePickerView

        init(_ parent: ImagePickerView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
                parent.onImagePicked?(image) // ✅ safe upload trigger
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
#elseif os(macOS)
import AppKit

struct ImagePickerView: NSViewControllerRepresentable {
    @Binding var selectedImage: PlatformImage?
    var onImagePicked: ((PlatformImage) -> Void)? // ✅ callback

    func makeNSViewController(context: Context) -> NSViewController {
        return ImagePickerViewController(selectedImage: $selectedImage, onImagePicked: onImagePicked)
    }

    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {}
}

final class ImagePickerViewController: NSViewController {
    @Binding var selectedImage: PlatformImage?
    var onImagePicked: ((PlatformImage) -> Void)?

    init(selectedImage: Binding<PlatformImage?>, onImagePicked: ((PlatformImage) -> Void)?) {
        _selectedImage = selectedImage
        self.onImagePicked = onImagePicked
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .bmp]
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.begin { response in
            if response == .OK, let url = panel.url,
               let image = NSImage(contentsOf: url) {
                self.selectedImage = image
                self.onImagePicked?(image) // ✅ safe upload trigger
            }
            self.dismiss(self)
        }
    }
}
#endif
