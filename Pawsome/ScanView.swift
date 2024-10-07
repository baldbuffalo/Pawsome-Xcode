import SwiftUI
import AVFoundation

struct ScanView: View {
    @State private var capturedImage: UIImage?
    @State private var isLoading = false
    @State private var isNavigatingToForm = false
    @State private var zoomFactor: CGFloat = 1.0 // State variable for zoom factor

    var body: some View {
        NavigationStack {
            ZStack {
                iOSCameraView(capturedImage: $capturedImage, zoomFactor: $zoomFactor) { image in
                    // This closure is called when the image is captured
                    self.isLoading = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { // Simulate loading
                        self.isLoading = false
                        self.capturedImage = image // Set the captured image
                        isNavigatingToForm = true // Trigger navigation when image is set
                    }
                }
                .edgesIgnoringSafeArea(.all)

                if isLoading {
                    ProgressView("Loading...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                        .background(Color.white.opacity(0.7))
                        .cornerRadius(10)
                }

                VStack {
                    Spacer() // Push the button to the bottom

                    // Zoom Slider
                    Slider(value: $zoomFactor, in: 1...5, step: 0.1)
                        .padding()
                        .accentColor(.blue)
                    Text("Zoom: \(String(format: "%.1f", zoomFactor))x") // Display zoom level

                    Button(action: {
                        isLoading = true // Show loading spinner
                        capturePhoto() // Trigger photo capture
                    }) {
                        Text("Capture Image")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding()
                    .blur(radius: isLoading ? 5 : 0)
                }
            }
            .navigationTitle("Scan")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $isNavigatingToForm) { // Navigate to Form view
                Form(imageUI: capturedImage) // Pass captured image to Form
            }
        }
    }

    private func capturePhoto() {
        // Simulate the photo capture for now, since iOSCameraView manages real capture
        // In your app, ensure iOSCameraView properly calls capture and processes the image
    }
}

#if os(iOS)
struct iOSCameraView: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    @Binding var zoomFactor: CGFloat // Add zoom factor binding
    var onCapture: (UIImage) -> Void // Callback for captured image

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        context.coordinator.setupCamera(in: viewController)
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Update the zoom factor whenever it changes
        if let device = AVCaptureDevice.default(for: .video) {
            try? device.lockForConfiguration()
            device.videoZoomFactor = zoomFactor
            device.unlockForConfiguration()
        }
    }

    class Coordinator: NSObject, AVCapturePhotoCaptureDelegate {
        var parent: iOSCameraView
        var captureSession: AVCaptureSession?
        var photoOutput: AVCapturePhotoOutput?

        init(_ parent: iOSCameraView) {
            self.parent = parent
        }

        func setupCamera(in viewController: UIViewController) {
            captureSession = AVCaptureSession()

            guard let videoCaptureDevice = AVCaptureDevice.default(for: .video),
                  let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice),
                  let captureSession = captureSession else { return }

            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            }

            photoOutput = AVCapturePhotoOutput()
            if let photoOutput = photoOutput, captureSession.canAddOutput(photoOutput) {
                captureSession.addOutput(photoOutput)
            }

            let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.frame = viewController.view.bounds
            viewController.view.layer.addSublayer(previewLayer)

            captureSession.startRunning()
        }

        // Delegate function for processing captured photo
        func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
            if let data = photo.fileDataRepresentation(), let image = UIImage(data: data) {
                parent.onCapture(image) // Call the capture callback with the image
            } else {
                parent.capturedImage = nil // Ensure captured image is nil if capture fails
            }
        }
    }
}
#endif
