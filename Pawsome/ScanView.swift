import SwiftUI
import PhotosUI
import AVKit
import UniformTypeIdentifiers

struct ScanView: View {
    @Binding var capturedImage: UIImage? // Binding to pass captured image back to HomeView
    var onImageCaptured: () -> Void // Closure to trigger when image is captured
    var username: String // Username to be passed

    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedVideoURL: URL? = nil

    var body: some View {
        VStack {
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

            PhotosPicker(selection: $selectedItem, matching: .any(of: [.images, .videos])) {
                Text("Select a photo or video")
            }
            .padding()
            .onChange(of: selectedItem) { _ in
                Task {
                    guard let selectedItem = selectedItem else { return }
                    
                    if let uti = try? await selectedItem.loadTransferable(type: String.self),
                       let mediaType = UTType(uti) {
                        
                        if mediaType.conforms(to: .image) {
                            if let data = try? await selectedItem.loadTransferable(type: Data.self) {
                                capturedImage = UIImage(data: data)
                                selectedVideoURL = nil
                                onImageCaptured() // Trigger closure when an image is captured
                            }
                        } else if mediaType.conforms(to: .movie) {
                            if let data = try? await selectedItem.loadTransferable(type: Data.self) {
                                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("tempVideo.mov")
                                try? data.write(to: tempURL)
                                selectedVideoURL = tempURL
                                capturedImage = nil
                            }
                        }
                    }
                }
            }
        }
        .padding()
    }
}
