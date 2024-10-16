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
    @State private var isVideoPickerPresented: Bool = false
    @State private var sourceType: UIImagePickerController.SourceType = .camera
    @State private var mediaType: ImagePicker.MediaType = .photo // Change this to use ImagePicker.MediaType
    @State private var showActionSheet: Bool = false // Controls the display of the action sheet
    @State private var isLoading: Bool = false // Loading state for feedback

    var body: some View {
        VStack(spacing: 20) {
            // Title
            Text("Capture or Select Media")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)

            // Display the selected image or video
            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 300)
                    .cornerRadius(12)
                    .shadow(radius: 8)
                    .padding(.horizontal)
            } else if let videoURL = selectedVideoURL {
                VideoPlayer(player: AVPlayer(url: videoURL))
                    .frame(height: 300)
                    .cornerRadius(12)
                    .shadow(radius: 8)
                    .padding(.horizontal)
                    .onAppear {
                        AVPlayer(url: videoURL).play() // Autoplay the video
                    }
            } else {
                // Placeholder when no media is selected
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 300)
                    .overlay(
                        Text("No media selected")
                            .foregroundColor(.gray)
                    )
                    .padding(.horizontal)
            }

            // Button to show the action sheet (Post Button)
            Button(action: {
                showActionSheet = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Post")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(CustomButtonStyle())
            .actionSheet(isPresented: $showActionSheet) {
                ActionSheet(
                    title: Text("Choose Media Option"),
                    message: Text("Select an option to proceed"),
                    buttons: [
                        .default(Text("Take Photo")) {
                            sourceType = .camera
                            mediaType = .photo // Use ImagePicker.MediaType
                            isImagePickerPresented = true
                        },
                        .default(Text("Take Video")) {
                            sourceType = .camera
                            mediaType = .video // Use ImagePicker.MediaType
                            isImagePickerPresented = true
                        },
                        .default(Text("Select from Library")) {
                            sourceType = .photoLibrary
                            isImagePickerPresented = true
                        },
                        .cancel()
                    ]
                )
            }

            Spacer() // To push content to the top
        }
        .padding()
        // Sheet for image/video picker
        .sheet(isPresented: $isImagePickerPresented) {
            ImagePicker(sourceType: sourceType, mediaType: mediaType, selectedImage: $capturedImage, selectedVideoURL: $selectedVideoURL, onImageCaptured: {
                onImageCaptured()
                isImagePickerPresented = false // Dismiss the picker after capturing
            })
        }
        // Handling PhotosPicker changes
        .onChange(of: selectedItem) { newItem in
            if let newItem = newItem {
                Task {
                    await loadMedia(from: newItem)
                }
            }
        }
    }

    // Centralized media loading logic
    private func loadMedia(from item: PhotosPickerItem?) async {
        guard let item = item else { return }

        // Load the asset's uniform type identifier (UTI)
        if let uti = try? await item.loadTransferable(type: String.self),
           let mediaType = UTType(uti) {

            isLoading = true // Start loading feedback

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

            isLoading = false // End loading feedback
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

// ImagePicker remains unchanged
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

            parent.onImageCaptured()
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
