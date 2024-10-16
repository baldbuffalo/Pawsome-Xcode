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

            // PhotosPicker button to select media
            PhotosPicker(selection: $selectedItem, matching: .any(of: [.images, .videos])) {
                Text("Select a photo or video")
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
    }
}
