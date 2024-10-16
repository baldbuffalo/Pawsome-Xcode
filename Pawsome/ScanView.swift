import SwiftUI
import PhotosUI
import AVKit
import UniformTypeIdentifiers

struct ScanView: View {
    @Binding var capturedImage: UIImage? // Binding to pass the captured image back to HomeView
    var onImageCaptured: () -> Void // Closure to trigger when the image is captured
    var username: String // Username to be passed

    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedVideoURL: URL? = nil
    @State private var isImagePickerPresented: Bool = false
    @State private var sourceType: UIImagePickerController.SourceType = .camera
    @State private var mediaType: ImagePicker.MediaType = .photo

    var body: some View {
        VStack(spacing: 20) {
            // Button to take photo directly
            Button(action: {
                sourceType = .camera
                mediaType = .photo
                isImagePickerPresented = true // Directly launch image picker for photo
            }) {
                HStack {
                    Image(systemName: "camera")
                    Text("Take Photo")
                }
            }
            .buttonStyle(CustomButtonStyle())

            // Spacer to push content to the top
            Spacer()
        }
        .padding()
        // Sheet for image/video picker
        .sheet(isPresented: $isImagePickerPresented) {
            ImagePicker(
                sourceType: sourceType,
                mediaType: mediaType,
                selectedImage: $capturedImage,
                selectedVideoURL: $selectedVideoURL,
                onImageCaptured: {
                    // Trigger the closure to notify when an image is captured
                    onImageCaptured()
                    isImagePickerPresented = false // Dismiss the picker after capturing
                }
            )
        }
        // Handling PhotosPicker changes
        .onChange(of: selectedItem) { newItem, _ in // Updated onChange
            Task {
                await loadMedia(from: newItem)
            }
        }
    }

    // Centralized media loading logic
    private func loadMedia(from item: PhotosPickerItem?) async {
        guard let item = item else { return }

        // Load the asset's uniform type identifier (UTI)
        if let uti = try? await item.loadTransferable(type: String.self),
           let mediaType = UTType(uti) {

            // Handle selected image
            if mediaType.conforms(to: .image) {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    capturedImage = UIImage(data: data)
                    selectedVideoURL = nil // Clear video if image is selected
                    onImageCaptured() // Trigger closure when an image is captured
                }
            }

            // Handle selected video
            else if mediaType.conforms(to: .movie) {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("tempVideo.mov")
                    try? data.write(to: tempURL)
                    selectedVideoURL = tempURL
                    capturedImage = nil // Clear image if video is selected
                }
            }
        }
    }
}

// Custom button style for better visual appeal
struct CustomButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .shadow(radius: configuration.isPressed ? 2 : 8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

// ImagePicker struct remains unchanged
struct ImagePicker: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType
    var mediaType: MediaType
    @Binding var selectedImage: UIImage?
    @Binding var selectedVideoURL: URL?
    var onImageCaptured: () -> Void

    enum MediaType {
        case photo
        case video
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator

        // Set media type (photo or video)
        switch mediaType {
        case .photo:
            picker.mediaTypes = ["public.image"]
        case .video:
            picker.mediaTypes = ["public.movie"]
        }

        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
                parent.selectedVideoURL = nil // Clear video if image is selected
            } else if let videoURL = info[.mediaURL] as? URL {
                parent.selectedVideoURL = videoURL
                parent.selectedImage = nil // Clear image if video is selected
            }

            parent.onImageCaptured() // Trigger the closure
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
