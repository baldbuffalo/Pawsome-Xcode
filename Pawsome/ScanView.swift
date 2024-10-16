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
    @State private var mediaType: String = "photo" // Tracks whether the user selected photo or video

    var body: some View {
        VStack {
            // Display the selected image or video
            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 300)
                    .cornerRadius(12)
            } else if let videoURL = selectedVideoURL {
                VideoPlayer(player: AVPlayer(url: videoURL))
                    .frame(height: 300)
                    .cornerRadius(12)
                    .onAppear {
                        AVPlayer(url: videoURL).play() // Autoplay the video
                    }
            }
            
            // Buttons to select from library or take photo/video
            HStack {
                Button("Take Photo") {
                    sourceType = .camera
                    mediaType = "photo"
                    isImagePickerPresented = true
                }
                .padding()

                Button("Take Video") {
                    sourceType = .camera
                    mediaType = "video"
                    isVideoPickerPresented = true
                }
                .padding()
            }

            // PhotosPicker button to select media from the photo library
            PhotosPicker(selection: $selectedItem, matching: .any(of: [.images, .videos])) {
                Text("Select from Library")
            }
            .padding()
            // Updated onChange to use the new iOS 17+ format
            .onChange(of: selectedItem) {
                Task {
                    guard let selectedItem = selectedItem else { return }
                    
                    // Load the asset's uniform type identifier (UTI)
                    if let uti = try? await selectedItem.loadTransferable(type: String.self),
                       let mediaType = UTType(uti) {
                        
                        // Handle selected image
                        if mediaType.conforms(to: .image) {
                            if let data = try? await selectedItem.loadTransferable(type: Data.self) {
                                capturedImage = UIImage(data: data)
                                selectedVideoURL = nil // Clear video if image is selected
                                onImageCaptured() // Trigger closure when an image is captured
                            }
                        }
                        
                        // Handle selected video
                        else if mediaType.conforms(to: .movie) {
                            if let data = try? await selectedItem.loadTransferable(type: Data.self) {
                                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("tempVideo.mov")
                                try? data.write(to: tempURL)
                                selectedVideoURL = tempURL
                                capturedImage = nil // Clear image if video is selected
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .sheet(isPresented: $isImagePickerPresented) {
            ImagePicker(sourceType: sourceType, mediaType: mediaType == "photo" ? .photo : .video, selectedImage: $capturedImage, selectedVideoURL: $selectedVideoURL, onImageCaptured: onImageCaptured)
        }
    }
}

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
