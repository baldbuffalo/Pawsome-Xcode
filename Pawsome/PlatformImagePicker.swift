import SwiftUI

struct PlatformImagePicker: View {
    var onImagePicked: (PlatformImage) -> Void

    @State private var isPresented = true

    var body: some View {
        EmptyView()
            .sheet(isPresented: $isPresented) {
                #if os(iOS)
                ImagePickerIOS { img in
                    onImagePicked(img)
                }
                #elseif os(macOS)
                ImagePickerMac { img in
                    onImagePicked(img)
                }
                #endif
            }
    }
}

#if os(iOS)
import UIKit

struct ImagePickerIOS: UIViewControllerRepresentable {
    var onPicked: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPicked: onPicked)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
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
    }
}
#endif

#if os(macOS)
import AppKit

struct ImagePickerMac: NSViewControllerRepresentable {
    var onPicked: (NSImage) -> Void

    func makeNSViewController(context: Context) -> NSViewController {
        let vc = NSViewController()
        DispatchQueue.main.async {
            let panel = NSOpenPanel()
            panel.allowedContentTypes = [.image]
            panel.begin { response in
                if response == .OK, let url = panel.url, let img = NSImage(contentsOf: url) {
                    onPicked(img)
                }
            }
        }
        return vc
    }

    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {}
}
#endif
