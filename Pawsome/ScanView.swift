import SwiftUI
import AVFoundation

struct ScanView: View {
    @State private var capturedImage: UIImage? = nil // State to hold the captured image
    private let captureSession = AVCaptureSession() // Camera capture session
    @State private var videoOutput = AVCapturePhotoOutput() // Make videoOutput mutable with @State

    var body: some View {
        VStack {
            CameraPreview(capturedImage: $capturedImage, captureSession: captureSession, videoOutput: videoOutput)
                .frame(height: 300) // Adjust the height as needed
            
            Button(action: {
                capturePhoto() // Capture photo when the button is pressed
            }) {
                Text("Capture Photo")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200) // Adjust the size as needed
            }
        }
        .padding()
        .onAppear {
            setupCamera() // Set up the camera session when the view appears
        }
    }

    private func setupCamera() {
        // Set up camera input
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }

        // Add input to the session
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            return
        }

        // Initialize and set up photo output
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }

        // Start the camera session
        captureSession.startRunning()
    }

    private func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        videoOutput.capturePhoto(with: settings, delegate: makeCoordinator())
    }

    private func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    // Coordinator to handle the photo capturing
    class Coordinator: NSObject, AVCapturePhotoCaptureDelegate {
        var parent: ScanView

        init(_ parent: ScanView) {
            self.parent = parent
            super.init()
        }

        func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
            guard let imageData = photo.fileDataRepresentation(), error == nil else {
                print("Error capturing photo: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            // Convert the image data to a UIImage and assign it to the binding
            if let image = UIImage(data: imageData) {
                // Use DispatchQueue.main to update the UI
                DispatchQueue.main.async {
                    self.parent.capturedImage = image // Correctly update the binding
                }
            }
        }
    }
}

// CameraPreview Component
struct CameraPreview: UIViewRepresentable {
    @Binding var capturedImage: UIImage?
    let captureSession: AVCaptureSession
    var videoOutput: AVCapturePhotoOutput

    func makeUIView(context: Context) -> UIView {
        let view = UIView()

        // Set up the preview layer
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Update the preview layer frame when the view's bounds change
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = uiView.layer.bounds
        }
    }
}
