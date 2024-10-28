import SwiftUI

struct ImageEditing: View {
    @Binding var capturedImage: UIImage? // Binding to the captured image
    @Binding var hideTabBar: Bool // Binding to control tab bar visibility
    @State private var isCropping: Bool = false // State to manage cropping
    @State private var cropRect: CGRect = .zero // State for cropping rectangle

    var body: some View {
        VStack {
            if let image = capturedImage {
                if isCropping {
                    GeometryReader { geometry in
                        ZStack {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .clipped()
                                .gesture(DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        // Update the cropping rectangle based on drag gesture
                                        let frame = geometry.frame(in: .global)
                                        let size = CGSize(width: frame.size.width * 0.8, height: frame.size.height * 0.8)
                                        let origin = CGPoint(x: value.startLocation.x - size.width / 2, y: value.startLocation.y - size.height / 2)
                                        cropRect = CGRect(origin: origin, size: size)
                                    }
                                )
                                .overlay(
                                    Rectangle()
                                        .path(in: cropRect)
                                        .stroke(Color.red, lineWidth: 2)
                                )

                            VStack {
                                Spacer()
                                Button("Crop Image") {
                                    cropImage()
                                }
                                .padding()
                            }
                        }
                    }
                    .frame(height: 300)
                } else {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 300)
                        .padding()

                    // Add editing options here (e.g., filters, cropping, etc.)
                    Text("Editing Options")
                        .font(.headline)
                        .padding()

                    // Button to open cropping interface
                    Button("Crop Image") {
                        isCropping = true // Show the crop view
                    }
                    .padding()

                    // Example button to discard the editing
                    Button("Done Editing") {
                        capturedImage = nil // Reset the captured image
                        hideTabBar = false // Show the tab bar again after editing
                    }
                    .padding()
                }
            } else {
                Text("No Image Captured")
            }
        }
        .navigationTitle("Edit Cat Image")
    }

    private func cropImage() {
        guard let cgImage = capturedImage?.cgImage else { return }
        
        // Crop the image based on the defined crop rectangle
        let croppedCGImage = cgImage.cropping(to: cropRect)
        if let croppedUIImage = croppedCGImage.map(UIImage.init) {
            capturedImage = croppedUIImage // Update the captured image with the cropped version
        }
        isCropping = false // Exit cropping mode
    }
}
