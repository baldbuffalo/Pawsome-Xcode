import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
import UniformTypeIdentifiers
#endif

/// PlatformImagePicker: cross-platform wrapper
/// Usage:
/// .sheet(isPresented: $isPresented) {
///     PlatformImagePicker { img in
///         // handle PlatformImage (UIImage on iOS, NSImage on macOS)
///     }
/// }
struct PlatformImagePicker: View {
    var onSelect: (PlatformImage) -> Void

    var body: some View {
        #if os(iOS)
        ImagePickerIOS(onPicked: onSelect)
        #elseif os(macOS)
        ImagePickerMac(onPicked: onSelect)
        #endif
    }
}

#if os(iOS)
// MARK: - iOS UIImagePickerController wrapper
struct ImagePickerIOS: UIViewControllerRepresentable {
    var onPicked: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onPicked: onPicked) }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let onPicked: (UIImage) -> Void
        init(onPicked: @escaping (UIImage) -> Void) { self.onPicked = onPicked }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
        ) {
            let img = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage)
            if let img = img { onPicked(img) }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
#endif

#if os(macOS)
// MARK: - macOS NSOpenPanel wrapper
// We present the open panel from a view controller's viewDidAppear to ensure the window is ready.
final class ImagePickerHostViewController: NSViewController {
    var onPicked: (NSImage) -> Void
    private var didAppearOnce = false

    init(onPicked: @escaping (NSImage) -> Void) {
        self.onPicked = onPicked
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidAppear() {
        super.viewDidAppear()
        // show panel only once
        guard !didAppearOnce else { return }
        didAppearOnce = true

        // present open panel shortly after appearance to avoid early-window issues
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            let panel = NSOpenPanel()
            panel.allowedContentTypes = [UTType.image]
            panel.allowsMultipleSelection = false
            panel.canChooseDirectories = false
            panel.beginSheetModal(for: self.view.window ?? NSApp.mainWindow!) { response in
                if response == .OK, let url = panel.url, let img = NSImage(contentsOf: url) {
                    self.onPicked(img)
                }
                // close the sheet host controller's window (the sheet dismiss will propagate)
                self.dismiss(self)
            }
        }
    }
}

struct ImagePickerMac: NSViewControllerRepresentable {
    var onPicked: (NSImage) -> Void

    func makeNSViewController(context: Context) -> NSViewController {
        return ImagePickerHostViewController(onPicked: onPicked)
    }

    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {}
}
#endif
