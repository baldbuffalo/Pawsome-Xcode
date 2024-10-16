import SwiftUI
import PhotosUI
import AVKit
import UniformTypeIdentifiers

struct ScanView: View {
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var selectedVideoURL: URL? = nil
    
    var body: some View {
        VStack {
            // Display the selected image or video
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 300)
                    .cornerRadius(12)
            } else if let videoURL = selectedVideoURL {
                // Display the video player when a video is selected
                VideoPlayer(player: AVPlayer(url: videoURL))
                    .frame(height: 300)
                    .cornerRadius(12)
                    .onAppear() {
                        AVPlayer(url: videoURL).play() // Autoplay the video
                    }
            }

            // PhotosPicker button to select media
            PhotosPicker(selection: $selectedItem, matching: .any(of: [.images, .videos])) {
                Text("Select a photo or video")
            }
            .padding()
            .onChange(of: selectedItem) { // Using the new onChange closure format
                Task {
                    guard let selectedItem = selectedItem else { return }
                    
                    // Load the asset's uniform type identifier (UTI)
                    if let uti = try? await selectedItem.loadTransferable(type: String.self),
                       let mediaType = UTType(uti) {
                        
                        // Handle selected image
                        if mediaType.conforms(to: .image) {
                            if let data = try? await selectedItem.loadTransferable(type: Data.self) {
                                selectedImage = UIImage(data: data)
                                selectedVideoURL = nil // Clear video if image is selected
                            }
                        }
                        
                        // Handle selected video
                        else if mediaType.conforms(to: .movie) {
                            if let data = try? await selectedItem.loadTransferable(type: Data.self) {
                                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("tempVideo.mov")
                                try? data.write(to: tempURL)
                                selectedVideoURL = tempURL
                                selectedImage = nil // Clear image if video is selected
                            }
                        }
                    }
                }
            }
        }
        .padding()
    }
}
