#if canImport(AppKit)
import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ImagePicker_macOS: NSViewControllerRepresentable {
    @Binding var image: NSImage?

    class Coordinator: NSObject {
        var parent: ImagePicker_macOS

        init(parent: ImagePicker_macOS) {
            self.parent = parent
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    func makeNSViewController(context: Context) -> NSViewController {
        let viewController = NSViewController()
        
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowedContentTypes = [.jpeg, .png]  // Replaces allowedFileTypes
        openPanel.allowsMultipleSelection = false
        
        openPanel.begin { result in
            if result == .OK, let url = openPanel.url {
                if let image = NSImage(contentsOf: url) {
                    self.image = image
                }
            }
        }
        
        return viewController
    }

    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {}
}
#endif
