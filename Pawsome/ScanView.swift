import SwiftUI
import PhotosUI

struct ScanView: View {
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var selectedVideoURL: URL? = nil
    @State private var isFormShown: Bool = false

    var body: some View {
        VStack {
            PhotosPicker(
                selection: $selectedItem,
                matching: .any(of: [.images, .videos]),
                photoLibrary: .shared()
            ) {
                Text("Select Image or Video") // Correct closure with no parameters
            }
            .onChange(of: selectedItem) { newItem in
                Task {
                    // Retrieve selected asset
                    if let newItem = newItem {
                        // Check the media type and load data accordingly
                        if newItem.mediaType == .image {
                            if let data = try? await newItem.loadTransferable(type: Data.self) {
                                selectedImage = UIImage(data: data)
                            }
                        } else if newItem.mediaType == .video {
                            if let data = try? await newItem.loadTransferable(type: Data.self) {
                                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("tempVideo.mov")
                                try? data.write(to: tempURL)
                                selectedVideoURL = tempURL
                            }
                        }
                    }
                }
            }

            Button("Open Form") {
                isFormShown = true
            }
            .sheet(isPresented: $isFormShown) {
                // Pass the selected image or video URL to FormView
                FormView(
                    showForm: $isFormShown,
                    imageUI: selectedImage,
                    videoURL: selectedVideoURL,
                    username: "User", // Pass the actual username as needed
                    onPostCreated: { post in
                        // Handle post creation
                    }
                )
            }
        }
        .padding()
    }
}
