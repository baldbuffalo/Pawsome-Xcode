import SwiftUI
#if os(iOS)
import PhotosUI
#endif

struct ScanView: View {
    @State private var selectedImage: PlatformImage? = nil
    @State private var showForm: Bool = false
    @State private var showSourcePicker: Bool = false
    @State private var showCameraPicker: Bool = false
    @State private var showPhotoPicker: Bool = false

    var username: String
    var onPostCreated: (() -> Void)? // callback closure

    // 🔑 Binding to parent flow state
    @Binding var activeHomeFlow: PawsomeApp.HomeFlow?

    var body: some View {
        VStack(spacing: 20) {
            if !showForm {
                Button("Choose Image") {
                    showSourcePicker = true
                }
                .padding()
                .foregroundColor(.white)
                .background(Color.blue)
                .cornerRadius(8)
                .confirmationDialog("Select Image Source", isPresented: $showSourcePicker, titleVisibility: .visible) {
                    #if os(iOS)
                    Button("Open Camera") { showCameraPicker = true }
                    Button("Open Photos") { showPhotoPicker = true }
                    #elseif os(macOS)
                    Button("Open Photos") { pickFile() }
                    #endif
                    Button("Cancel", role: .cancel) {}
                }
            }

            if showForm, let img = selectedImage {
                FormView(
                    showForm: $showForm,
                    navigateToHome: .constant(false),
                    image: img,
                    username: username,
                    onPostCreated: onPostCreated,
                    activeHomeFlow: $activeHomeFlow // Pass flow to FormView
                )
                .frame(maxHeight: 600)
            }
        }
        .padding()
        .onAppear {
            // Set tab to Scan when ScanView opens
            activeHomeFlow = .scan
        }
        #if os(iOS)
        .sheet(isPresented: $showCameraPicker) {
            ImagePicker(sourceType: .camera) { img in
                selectedImage = img
                showForm = true
            }
        }
        .sheet(isPresented: $showPhotoPicker) {
            ImagePicker(sourceType: .photoLibrary) { img in
                selectedImage = img
                showForm = true
            }
        }
        #endif
    }

    // MARK: - macOS file picker
    #if os(macOS)
    private func pickFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK,
           let url = panel.urls.first,
           let img = PlatformImage(contentsOf: url) {
            selectedImage = img
            showForm = true
        }
    }
    #endif
}

// MARK: - UIImagePickerController wrapper for iOS
#if os(iOS)
struct ImagePicker: UIViewControllerRepresentable {
    enum SourceType { case camera, photoLibrary }
    var sourceType: SourceType
    var completion: (PlatformImage?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = (sourceType == .camera) ? .camera : .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            parent.completion(info[.originalImage] as? UIImage)
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.completion(nil)
            picker.dismiss(animated: true)
        }
    }
}
#endif
