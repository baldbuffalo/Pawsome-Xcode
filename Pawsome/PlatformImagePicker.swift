import SwiftUI

// MARK: - PlatformImagePicker Wrapper
struct PlatformImagePicker: View {
    var onImagePicked: (PlatformImage) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isPresented = true

    var body: some View {
        EmptyView()
            .sheet(isPresented: $isPresented) {
                #if os(iOS)
                ImagePickerIOS { img in
                    onImagePicked(img)
                    dismiss()
                }
                #elseif os(macOS)
                ImagePickerMac { img in
                    onImagePicked(img)
                    dismiss()
                }
                #endif
            }
    }
}

#if os(iOS)
// MARK: - iOS Image Picker
import UIKit

struct ImagePickerIOS: UIViewControllerRepresentable {
    var onPicked: (UIImage) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onPicked: onPicked)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onPicked: (UIImage) -> Void

        init(onPicked: @escaping (UIImage) -> Void) {
            self.onPicked = onPicked
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
        ) {
            if let img = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                onPicked(img)
            }

            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
#endif


#if os(macOS)
// MARK: - macOS Image Picker
import AppKit

struct ImagePickerMac: NSViewControllerRepresentable {
    var onPicked: (NSImage) -> Void

    func makeNSViewController(context: Context) -> NSViewController {
        let viewController = NSViewController()

        DispatchQueue.main.async {
            let panel = NSOpenPanel()
            panel.canChooseFiles = true
            panel.allowedContentTypes = [.image]

            panel.begin { response in
                if response == .OK,
                   let url = panel.url,
                   let img = NSImage(contentsOf: url) {
                    onPicked(img)
                }
            }
        }

        return viewController
    }

    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {}
}
#endif
