import SwiftUI

struct ScanView: View {
    @State private var selectedImage: PlatformImage? = nil
    @State private var showForm: Bool = false
    @State private var showSourcePicker: Bool = false
    @State private var useCamera: Bool = false

    var username: String
    var onPostCreated: (() -> Void)? // ✅ now matches FormView

    var body: some View {
        VStack(spacing: 20) {
            Button("Choose Image") {
                showSourcePicker = true
            }
            .padding()
            .foregroundColor(.white)
            .background(Color.blue)
            .cornerRadius(8)
            .confirmationDialog("Select Image Source", isPresented: $showSourcePicker, titleVisibility: .visible) {
                #if os(iOS)
                Button("Open Camera") {
                    useCamera = true
                    showForm = true
                }
                #endif
                Button("Open Files") {
                    useCamera = false
                    pickFile()
                }
                Button("Cancel", role: .cancel) {}
            }

            if showForm, let img = selectedImage {
                FormView(
                    showForm: $showForm,
                    navigateToHome: .constant(false),
                    image: img,
                    username: username,
                    onPostCreated: onPostCreated // ✅ same closure type now
                )
                .frame(maxHeight: 600)
            }
        }
        .padding()
    }

    private func pickFile() {
        #if os(macOS)
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK,
           let url = panel.urls.first,
           let img = PlatformImage(contentsOf: url) {
            selectedImage = img
            showForm = true
        }
        #elseif os(iOS)
        showForm = true // simulated
        #endif
    }
}
