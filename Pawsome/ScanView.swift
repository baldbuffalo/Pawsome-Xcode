import SwiftUI
import AVFoundation

struct ScanView: View {
    @Binding var capturedImage: UIImage? // Binding to capture image
    @Binding var hideTabBar: Bool // Binding to control tab bar visibility
    @Binding var catPosts: [CatPost] // Binding to an array of CatPost
    @State private var isNavigating = false // State to trigger navigation
    @State private var navigationTag: String? = nil // Tag for NavigationLink

    var body: some View {
        NavigationStack {
            VStack {
                Text("Take a Picture of Your Cat")
                    .font(.headline)
                    .padding()

                Button("Open Camera") {
                    openCamera() // Directly open the camera
                }
                .padding()

                // New way to handle navigation using NavigationLink and navigationDestination
                NavigationLink(
                    destination: FormView(showForm: $isNavigating, catPosts: $catPosts, imageUI: capturedImage),
                    tag: "FormView",
                    selection: $navigationTag // Navigate based on this tag
                ) {
                    EmptyView() // Hidden NavigationLink
                }
            }
            .navigationTitle("Scan Cat")
        }
    }

    private func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            print("Camera not available on this device")
            return
        }

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let topController = windowScene.windows.first?.rootViewController else {
            return
        }

        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.delegate = makeCoordinator() // Set the coordinator as delegate
        topController.present(imagePicker, animated: true)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: ScanView

        init(_ parent: ScanView) {
            self.parent = parent
        }

        // Automatically use the picture once it is taken
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.capturedImage = image // Set the captured image
                parent.navigationTag = "FormView"   // Trigger navigation to FormView
            }
            picker.dismiss(animated: true) // Dismiss the camera view automatically
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
