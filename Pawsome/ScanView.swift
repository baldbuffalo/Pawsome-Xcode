import SwiftUI
import AVFoundation

struct ScanView: View {
    @Binding var capturedImage: UIImage?
    @Binding var hideTabBar: Bool // Binding to control the visibility of the tab bar

    var body: some View {
        ZStack {
            CameraPreview(capturedImage: $capturedImage)
                .edgesIgnoringSafeArea(.all) // Fill the entire screen

            VStack {
                Spacer() // Pushes the capture button to the bottom

                Button(action: {
                    // Add capture image logic here
                    print("Capture button tapped")
                }) {
                    Text("Capture Image")
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.bottom, 40) // Padding from the bottom
            }
        }
        .onAppear {
            hideTabBar = true // Hide the tab bar when the Scan view appears
        }
        .onDisappear {
            hideTabBar = false // Show the tab bar again when leaving the Scan view
        }
    }
}

// UIViewRepresentable for Camera Preview
struct CameraPreview: UIViewRepresentable {
    @Binding var capturedImage: UIImage?

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return view }
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return view
        }

        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            return view
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        captureSession.startRunning()

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Update the UIView if needed
    }
}
