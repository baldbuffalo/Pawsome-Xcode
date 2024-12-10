import SwiftUI

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct ImageEditing: View {
    @Binding var capturedImage: Any? // Binding to the captured image (supports both UIImage and NSImage)
    @Binding var hideTabBar: Bool // Binding to control tab bar visibility
    @State private var isCropping: Bool = false // State to manage cropping
    @State private var cropRect: CGRect = .zero // State for cropping rectangle

    var body: some View {
        VStack {
            if let image = capturedImage {
                if isCropping {
                    GeometryReader { geometry in
                        ZStack {
                            imageView(image)
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
                    imageView(image)
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
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensures the view takes up the available space
        .background(Color.white) // Background color for better visibility, especially on macOS
        .cornerRadius(10) // Optional for rounded corners
        .padding()
    }

    private func cropImage() {
        guard let cgImage = imageToCGImage(capturedImage) else { return }
        
        // Crop the image based on the defined crop rectangle
        if let croppedCGImage = cgImage.cropping(to: cropRect) {
            capturedImage = imageFromCGImage(croppedCGImage) // Update the captured image with the cropped version
        }
        isCropping = false // Exit cropping mode
    }

    // Helper function to convert the image to CGImage
    private func imageToCGImage(_ image: Any) -> CGImage? {
        #if os(iOS)
        if let uiImage = image as? UIImage {
            return uiImage.cgImage
        }
        #elseif os(macOS)
        if let nsImage = image as? NSImage {
            return nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil)
        }
        #endif
        return nil
    }

    // Helper function to create a UIImage or NSImage from a CGImage
    private func imageFromCGImage(_ cgImage: CGImage) -> Any? {
        #if os(iOS)
        return UIImage(cgImage: cgImage)
        #elseif os(macOS)
        return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        #endif
    }

    // Helper function to return the correct image view for each platform
    private func imageView(_ image: Any) -> Image {
        #if os(iOS)
        if let uiImage = image as? UIImage {
            return Image(uiImage: uiImage)
        }
        #elseif os(macOS)
        if let nsImage = image as? NSImage {
            return Image(nsImage: nsImage)
        }
        #endif
        return Image(systemName: "photo") // Fallback in case the image is not available
    }
}
