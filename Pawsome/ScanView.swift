import SwiftUI
import AVFoundation

struct ScanView: View {
    @Binding var capturedImage: UIImage?
    @Binding var hideTabBar: Bool // Add this line to bind hideTabBar

    var body: some View {
        VStack {
            CameraPreview(capturedImage: $capturedImage)
                .frame(height: 300)
            
            Button(action: {
                NotificationCenter.default.post(name: NSNotification.Name("capturePhoto"), object: nil)
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
                    .frame(width: 200, height: 200)
            }
        }
        .padding()
    }
}

// CameraPreview Component
final class CameraPreview: UIViewRepresentable {
    @Binding var capturedImage: UIImage?
    let captureSession = AVCaptureSession() // Camera capture session
    var videoOutput: AVCapturePhotoOutput? // Photo output

    init(capturedImage: Binding<UIImage?>) {
        self._capturedImage = capturedImage
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()

        // Set up camera input
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return view }
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return view
        }

        // Add input to the session
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            return view
        }

        // Initialize and set up photo output here
        videoOutput = AVCapturePhotoOutput() // Initialize the AVCapturePhotoOutput
        if let videoOutput = videoOutput, captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }

        // Set up preview layer
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        // Start the camera session
        captureSession.startRunning()

        // Notify the context of updates
        context.coordinator.captureSession = captureSession

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Update the preview layer frame when the view's bounds change
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = uiView.layer.bounds
        }
    }

    func capturePhoto() {
        guard let videoOutput = videoOutput else { return }
        let settings = AVCapturePhotoSettings()
        videoOutput.capturePhoto(with: settings, delegate: makeCoordinator())
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // Coordinator to handle the photo capturing
    class Coordinator: NSObject, AVCapturePhotoCaptureDelegate {
        var parent: CameraPreview
        var captureSession: AVCaptureSession? // Keep a reference to the session

        init(_ parent: CameraPreview) {
            self.parent = parent
            super.init()
            
            // Set up notification observer
            NotificationCenter.default.addObserver(self, selector: #selector(captureImageNotification), name: NSNotification.Name("capturePhoto"), object: nil)
        }
        
        deinit {
            // Remove the notification observer
            NotificationCenter.default.removeObserver(self)
        }
        
        @objc func captureImageNotification() {
            // Capture photo using the existing context
            parent.capturePhoto() // Call without context since it's not needed
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
