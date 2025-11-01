import SwiftUI
#if os(iOS)
import UIKit
import MobileCoreServices
#endif
#if os(macOS)
import AppKit
#endif

// ------------------- NSImage Extension -------------------
#if os(macOS)
extension NSImage {
    func pngData() -> Data? {
        guard let tiff = self.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff) else { return nil }
        return bitmap.representation(using: .png, properties: [:])
    }
}
#endif

struct ScanView: View {
    #if os(iOS)
    @Binding var selectedImage: UIImage?
    #elseif os(macOS)
    @Binding var selectedImage: NSImage?
    #endif

    @State private var isImagePickerPresented: Bool = false
    @State private var showSourcePicker: Bool = false
    @State private var useCamera: Bool = false
    @State private var showForm: Bool = false // triggers navigationDestination

    var username: String
    var onPostCreated: ((CatPost) -> Void)?

    var body: some View {
        NavigationStack {
            VStack {
                Button("Choose Image") {
                    showSourcePicker = true
                }
                .padding()
                .foregroundColor(.white)
                .background(Color.blue)
                .cornerRadius(8)
                // ------------------- Confirmation Dialog -------------------
                #if os(iOS)
                .confirmationDialog("Select Image Source", isPresented: $showSourcePicker, titleVisibility: .visible) {
                    Button("Open Camera") { useCamera = true; isImagePickerPresented = true }
                    Button("Open Files") { useCamera = false; isImagePickerPresented = true }
                    Button("Cancel", role: .cancel) {}
                }
                #elseif os(macOS)
                .confirmationDialog("Select Image Source", isPresented: $showSourcePicker, titleVisibility: .visible) {
                    Button("Open Files") { openMacFilePicker() }
                    Button("Cancel", role: .cancel) {}
                }
                #endif

                #if os(iOS)
                // ------------------- iOS Image Picker Sheet -------------------
                .sheet(isPresented: $isImagePickerPresented) {
                    ZStack {
                        Color.black.opacity(0.001)
                            .ignoresSafeArea()
                            .onTapGesture { isImagePickerPresented = false }
                        ImagePicker(selectedImage: $selectedImage, useCamera: useCamera) {
                            showForm = true
                        }
                    }
                }
                #endif
            }
            // ------------------- NavigationDestination to FormView -------------------
            .navigationDestination(isPresented: $showForm) {
                if let imageData = selectedImage?.pngData() {
                    FormView(
                        showForm: $showForm,
                        navigateToHome: .constant(false),
                        imageUIData: imageData,
                        videoURL: nil,
                        username: username,
                        onPostCreated: { post in
                            onPostCreated?(post)
                            selectedImage = nil
                        }
                    )
                }
            }
        }
    }

    // ------------------- macOS File Picker -------------------
    #if os(macOS)
    private func openMacFilePicker() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK,
           let url = panel.urls.first,
           let image = NSImage(contentsOf: url) {
            selectedImage = image
            showForm = true // triggers navigationDestination
        }
    }
    #endif
}

// ------------------- iOS Image Picker -------------------
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
