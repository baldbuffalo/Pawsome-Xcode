import SwiftUI
import AVFoundation
import AVKit // Import AVKit for VideoPlayer

struct ScanView: View {
    @Binding var capturedImage: UIImage? // Binding to capture image
    @State private var capturedVideoURL: URL? // State to capture video URL
    @State private var showImagePicker: Bool = false // State to show image picker
    @State private var imagePickerSourceType: UIImagePickerController.SourceType = .camera // Source type for ImagePicker
    @State private var showActionSheet: Bool = false // State to show action sheet
    @State private var mediaType: String = "" // Keep track of whether it's photo or video

    var onImageCaptured: () -> Void // Closure to handle image capture
    var username: String // Add username parameter

    var body: some View {
        NavigationStack {
            VStack {
                Text("Capture a Picture or Video of Your Cat")
                    .font(.headline)
                    .padding()

                Button("Open Camera") {
                    showActionSheet = true // Show the action sheet when the button is pressed
                }
                .padding()

                // Show video player if a video URL is available
                if let videoURL = capturedVideoURL {
                    VideoView(videoURL: videoURL) // Display captured video
                        .frame(height: 300)
                }
            }
            .navigationTitle("Scan Cat")
            .actionSheet(isPresented: $showActionSheet) {
                ActionSheet(
                    title: Text("Choose Capture Option"),
                    buttons: [
                        .default(Text("Take Photo")) {
                            mediaType = "photo"
                            imagePickerSourceType = .camera
                            showImagePicker = true
                        },
                        .default(Text("Take Video")) {
                            mediaType = "video"
                            imagePickerSourceType = .camera
                            showImagePicker = true
                        },
                        .cancel()
                    ]
                )
            }
            // Show ImagePicker when triggered by action sheet
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(capturedImage: $capturedImage, capturedVideoURL: $capturedVideoURL, sourceType: imagePickerSourceType, mediaType: mediaType, onImagePicked: {
                    onImageCaptured()
                })
            }
            // Handle navigation to FormView
            .navigationDestination(isPresented: Binding<Bool>(
                get: { capturedImage != nil || capturedVideoURL != nil },
                set: { if !$0 { capturedImage = nil; capturedVideoURL = nil } }
            )) {
                if let capturedImage = capturedImage {
                    FormView(showForm: .constant(true), imageUI: capturedImage, username: username) { newPost in
                        // Handle the post creation logic here
                        print("New post created with image: \(newPost)")
                    }
                } else if let capturedVideoURL = capturedVideoURL {
                    // You may want to create a view to handle the video
                    VideoView(videoURL: capturedVideoURL) // Create a separate view to handle video playback
                }
            }
        }
    }
}

// New view for displaying the video
struct VideoView: View {
    var videoURL: URL

    var body: some View {
        VideoPlayer(player: AVPlayer(url: videoURL))
            .edgesIgnoringSafeArea(.all)
            .navigationTitle("Captured Video")
            .navigationBarTitleDisplayMode(.inline)
    }
}

// ImagePicker struct to handle the UIImagePickerController
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    @Binding var capturedVideoURL: URL?
    var sourceType: UIImagePickerController.SourceType
    var mediaType: String // "photo" or "video"
    var onImagePicked: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = context.coordinator
        imagePicker.sourceType = sourceType
        if mediaType == "photo" {
            imagePicker.mediaTypes = ["public.image"] // Only allow images
        } else if mediaType == "video" {
            imagePicker.mediaTypes = ["public.movie"] // Only allow videos
            imagePicker.videoQuality = .typeMedium // Set video quality
        }
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
            } else if let videoURL = info[.mediaURL] as? URL {
                parent.capturedVideoURL = videoURL // Set the captured video URL
            }
            parent.onImagePicked() // Call the closure to trigger navigation
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
