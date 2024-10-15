import SwiftUI
import AVFoundation

// Enum to represent navigation destinations
enum NavigationDestination: Hashable {
    case formView
}

struct ScanView: View {
    @Binding var capturedImage: UIImage? // Binding to capture image
    @Binding var catPosts: [CatPost] // Binding to an array of CatPost
    @State private var selectedDestination: NavigationDestination? // State to track navigation

    var body: some View {
        NavigationStack {
            VStack {
                Text("Take a Picture of Your Cat")
                    .font(.headline)
                    .padding()

                Button("Open Camera") {
                    openCamera()
                }
                .padding()

                // Use NavigationLink with `value` instead of `tag` and `selection`
                NavigationLink(
                    value: NavigationDestination.formView,
                    label: {
                        EmptyView() // NavigationLink is hidden but used for triggering
                    }
                )
            }
            .navigationTitle("Scan Cat")
            // Use `navigationDestination(for:destination:)` to handle navigation
            .navigationDestination(for: NavigationDestination.self) { destination in
                if destination == .formView {
                    FormView(showForm: .constant(false), catPosts: $catPosts, imageUI: capturedImage)
                }
            }
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
        imagePicker.delegate = makeCoordinator()
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

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.capturedImage = image // Set the captured image
                parent.selectedDestination = .formView // Trigger navigation to FormView
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
