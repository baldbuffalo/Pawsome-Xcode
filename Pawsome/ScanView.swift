import SwiftUI
#if os(iOS)
import PhotosUI
#endif

struct ScanView: View {
    @State private var selectedImage: PlatformImage? = nil
    @State private var showSourcePicker = false
    @State private var showCameraPicker = false
    @State private var showPhotoPicker = false
    @State private var isPickingFile = false

    var username: String
    var onPostCreated: (() -> Void)?

    @Binding var activeHomeFlow: PawsomeApp.HomeFlow?

    var body: some View {
        VStack(spacing: 20) {

            // PICK IMAGE
            if selectedImage == nil {
                Button("Choose Image") {
                    showSourcePicker = true
                }
                .padding()
                .foregroundColor(.white)
                .background(Color.blue)
                .cornerRadius(10)
                .confirmationDialog(
                    "Select Image Source",
                    isPresented: $showSourcePicker,
                    titleVisibility: .visible
                ) {
                    #if os(iOS)
                    Button("Camera") { showCameraPicker = true }
                    Button("Photos") { showPhotoPicker = true }
                    #elseif os(macOS)
                    Button("Photos") {
                        Task { await pickFile() }
                    }
                    #endif
                    Button("Cancel", role: .cancel) {}
                }
            }

            // SHOW FORM WHEN IMAGE EXISTS
            if let img = selectedImage {
                FormView(
                    image: img,
                    username: username,
                    onPostCreated: {
                        selectedImage = nil
                        activeHomeFlow = .home
                        onPostCreated?()
                    },
                    activeHomeFlow: $activeHomeFlow
                )
                .frame(maxHeight: 600)
            }
        }
        .padding()
        .onAppear {
            activeHomeFlow = .scan
        }

        // iOS PICKERS
        #if os(iOS)
        .sheet(isPresented: $showCameraPicker) {
            ImagePicker(sourceType: .camera) { img in
                guard let img else { return }
                selectedImage = img
            }
        }
        .sheet(isPresented: $showPhotoPicker) {
            ImagePicker(sourceType: .photoLibrary) { img in
                guard let img else { return }
                selectedImage = img
            }
        }
        #endif
    }

    // macOS PICKER
    #if os(macOS)
    @MainActor
    private func pickFile() async {
        guard !isPickingFile else { return }
        isPickingFile = true

        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK,
           let url = panel.urls.first,
           let img = PlatformImage(contentsOf: url) {
            selectedImage = img
        }

        isPickingFile = false
    }
    #endif
}

#if os(iOS)
struct ImagePicker: UIViewControllerRepresentable {
    enum SourceType { case camera, photoLibrary }
    var sourceType: SourceType
    var completion: (PlatformImage?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType == .camera ? .camera : .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
        ) {
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
