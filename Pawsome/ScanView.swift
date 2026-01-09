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
    var onPostCreated: (() -> Void)?

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
                    activeHomeFlow: $activeHomeFlow
                )
                .frame(maxHeight: 600)
            }
        }
        .padding()
        .onAppear {
            activeHomeFlow = .scan
        }
        // MARK: - iOS sheets
        #if os(iOS)
        .sheet(isPresented: $showCameraPicker) {
            ImagePicker(sourceType: .camera) { img in
                guard let img else { return }
                showCameraPicker = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    selectedImage = img
                    showForm = true
                }
            }
        }
        .sheet(isPresented: $showPhotoPicker) {
            ImagePicker(sourceType: .photoLibrary) { img in
                guard let img else { return }
                showPhotoPicker = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    selectedImage = img
                    showForm = true
                }
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                selectedImage = img
                showForm = true
            }
        }
    }
    #endif
}
