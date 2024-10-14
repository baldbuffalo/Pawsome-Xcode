import SwiftUI
import AVFoundation

struct ScanView: View {
    @Binding var capturedImage: UIImage? // Binding to capture image
    @Binding var hideTabBar: Bool // Binding to control tab bar visibility
    @Binding var catPosts: [CatPost] // Binding to an array of CatPost
    @State private var isNavigating = false // State to trigger navigation
    @State private var showEditingView = false // State to control visibility of ImageEditing

    var body: some View {
        VStack {
            Text("Take a Picture of Your Cat")
                .font(.headline)
                .padding()

            Button("Open Camera") {
                openCamera()
            }
            .padding()
        }
        .navigationTitle("Scan Cat")
        .onChange(of: capturedImage) { newImage in
            guard let image = newImage else { return }
            navigateToEditingView(with: image)
        }
        // Add NavigationLink for programmatic navigation to ImageEditing
        NavigationLink(destination: ImageEditing(capturedImage: $capturedImage, catPosts: $catPosts, hideTabBar: $hideTabBar), isActive: $showEditingView) {
            EmptyView() // Invisible link to handle navigation
        }
    }

    private func openCamera() {
        // Access the current scene
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let topController = windowScene.windows.first?.rootViewController else {
            return
        }

        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.delegate = makeCoordinator() // Set the coordinator as delegate
        topController.present(imagePicker, animated: true)
    }

    private func navigateToEditingView(with image: UIImage) {
        // Set the captured image for editing
        capturedImage = image
        hideTabBar = true // Hide the tab bar if needed
        
        // Trigger navigation
        showEditingView = true
    }

    // Coordinator to handle UIImagePickerController delegate
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: ScanView

        init(_ parent: ScanView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.capturedImage = image // Set the captured image
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
