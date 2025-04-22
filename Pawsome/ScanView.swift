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
    @State private var isImagePickerPresented: Bool = false
    @State private var errorMessage: String?

    // State variables for passing to FormView
    @State private var showForm: Bool = false
    @State private var navigateToHome: Bool = false
    var username: String = "YourUsername" // Replace this with your actual username or bind it to something

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
            .navigationTitle("Scan Cat")
            .navigationDestination(isPresented: $isImagePickerPresented) {
                // Pass the required arguments to FormView from Form.swift
                FormView(
                    showForm: $showForm,
                    navigateToHome: $navigateToHome,
                    imageUIData: selectedImage?.pngData(), // This line needs to be fixed for macOS
                    videoURL: nil, // Set to nil if you're not dealing with a video
                    username: username, // Pass your username here
                    onPostCreated: { catPost in
                        // Handle the post creation here
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
            onImageCaptured: { }
        )
        #elseif os(macOS)
        ImagePickerMac(selectedImage: $selectedImage)
        #endif
    }
}

#if os(iOS)
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    var onImageCaptured: () -> Void

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
            if panel.runModal() == .OK, let url = panel.urls.first, let image = NSImage(contentsOf: url) {
                selectedImage = image
            }
        }
    }
}
#endif

// Extension to convert NSImage to PNG Data in macOS
#if os(macOS)
extension NSImage {
    func pngData() -> Data? {
        guard let tiffRepresentation = self.tiffRepresentation else { return nil }
        let bitmap = NSBitmapImageRep(data: tiffRepresentation)
        let pngData = bitmap?.representation(using: .png, properties: [:])
        return pngData
    }
}
#endif
