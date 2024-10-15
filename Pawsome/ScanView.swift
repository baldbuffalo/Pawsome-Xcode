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
    @State private var showImagePicker: Bool = false // State to show image picker

    var body: some View {
        NavigationStack {
            VStack {
                Text("Take a Picture of Your Cat")
                    .font(.headline)
                    .padding()

                Button("Open Camera") {
                    showImagePicker = true // Show the image picker when the button is pressed
                }
                .padding()

                // Use NavigationLink with value to trigger navigation
                NavigationLink(destination: EmptyView(), isActive: Binding(
                    get: { selectedDestination == .formView },
                    set: { newValue in
                        if !newValue {
                            selectedDestination = nil
                        }
                    }
                )) {
                    EmptyView() // This will be triggered by the NavigationLink
                }
            }
            .navigationTitle("Scan Cat")
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(capturedImage: $capturedImage, onImagePicked: {
                    selectedDestination = .formView // Trigger navigation to FormView after picking the image
                })
            }
            // Handle navigation based on selectedDestination
            .navigationDestination(for: NavigationDestination.self) { destination in
                switch destination {
                case .formView:
                    FormView(showForm: .constant(false), catPosts: $catPosts, imageUI: capturedImage)
                }
            }
        }
    }

    private func openCamera() {
        showImagePicker = true // Set to true to open the image picker
    }
}

// ImagePicker struct to handle the UIImagePickerController
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    var onImagePicked: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = context.coordinator
        imagePicker.sourceType = .camera
        return imagePicker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.capturedImage = image // Set the captured image
                parent.onImagePicked() // Call the closure to trigger navigation
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
