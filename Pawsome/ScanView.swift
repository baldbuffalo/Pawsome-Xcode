import SwiftUI
import AVFoundation
import AVKit // Import AVKit for VideoPlayer

struct ScanView: View {
    @Binding var capturedImage: UIImage? // Binding to capture image
    @State private var capturedVideoURL: URL? // State to capture video URL
    @State private var showImagePicker: Bool = false // State to show image picker
    @State private var imagePickerSourceType: UIImagePickerController.SourceType = .camera // Source type for ImagePicker
    @State private var mediaTypes: [String] = ["public.image", "public.movie"] // Supported media types
    @State private var showActionSheet: Bool = false // State to show action sheet
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
                            imagePickerSourceType = .camera
                            mediaTypes = ["public.image"] // Set media types to only images
                            showImagePicker = true
                        },
                        .default(Text("Take Video")) {
                            imagePickerSourceType = .camera
                            mediaTypes = ["public.movie"] // Set media types to only videos
                            showImagePicker = true
                        },
                        .default(Text("Choose from Library")) {
                            imagePickerSourceType = .photoLibrary
                            mediaTypes = ["public.image", "public.movie"] // Allow both images and videos
                            showImagePicker = true
                        },
                        .cancel()
                    ]
                )
            }
            // Show ImagePicker when triggered by action sheet
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(capturedImage: $capturedImage, capturedVideoURL: $capturedVideoURL, sourceType: imagePickerSourceType, mediaTypes: mediaTypes, onImagePicked: {
                    // Call the closure when an image or video is picked
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
    var mediaTypes: [String] // Added mediaTypes to restrict what is shown
    var onImagePicked: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = context.coordinator
        imagePicker.sourceType = sourceType
        imagePicker.mediaTypes = mediaTypes // Use the media types provided
        imagePicker.videoQuality = .typeMedium // Set video quality
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
            } else if let videoURL = info[.mediaURL] as? URL {
                parent.capturedVideoURL = videoURL // Set the captured video URL
                parent.onImagePicked() // Call the closure to trigger navigation
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
