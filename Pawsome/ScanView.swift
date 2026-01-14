import SwiftUI
#if os(iOS)
import PhotosUI
#endif

struct ScanView: View {
    @EnvironmentObject var appState: PawsomeApp.AppState
    @Binding var activeHomeFlow: PawsomeApp.HomeFlow?

    var username: String

    @State private var showSourcePicker = false
    @State private var showCameraPicker = false
    @State private var showPhotoPicker = false
    @State private var isPickingFile = false

    var body: some View {
        VStack(spacing: 20) {
            Button("Choose Image") {
                showSourcePicker = true
            }
            .padding()
            .foregroundColor(.white)
            .background(Color.blue)
            .cornerRadius(10)
            .confirmationDialog("Select Image Source", isPresented: $showSourcePicker, titleVisibility: .visible) {
                #if os(iOS)
                Button("Camera") { showCameraPicker = true }
                Button("Photos") { showPhotoPicker = true }
                #elseif os(macOS)
                Button("Photos") { Task { await pickFile() } }
                #endif
                Button("Cancel", role: .cancel) {}
            }
        }
        .padding()
        .onAppear { activeHomeFlow = .scan }
        #if os(iOS)
        .sheet(isPresented: $showCameraPicker) {
            ImagePicker(sourceType: .camera) { img in
                guard let img = img else { return }
                DispatchQueue.main.async {
                    appState.selectedImage = img
                    activeHomeFlow = .form
                }
            }
        }
        .sheet(isPresented: $showPhotoPicker) {
            ImagePicker(sourceType: .photoLibrary) { img in
                guard let img = img else { return }
                DispatchQueue.main.async {
                    appState.selectedImage = img
                    activeHomeFlow = .form
                }
            }
        }
        #endif
    }

    #if os(macOS)
    @MainActor
    private func pickFile() async {
        guard !isPickingFile else { return }
        isPickingFile = true

        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        let response = await withCheckedContinuation { cont in
            panel.begin { r in cont.resume(returning: r) }
        }

        if response == .OK, let url = panel.urls.first, let img = PlatformImage(contentsOf: url) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                appState.selectedImage = img
                activeHomeFlow = .form
            }
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
            if let img = info[.originalImage] as? UIImage ?? info[.editedImage] as? UIImage {
                parent.completion(img)
            } else {
                parent.completion(nil)
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.completion(nil)
            picker.dismiss(animated: true)
        }
    }
}
#endif
