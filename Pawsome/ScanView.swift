import SwiftUI
import AVFoundation

struct ScanView: View {
    @State private var capturedImage: UIImage?
    @State private var isLoading = false

    var body: some View {
        ZStack {
            VStack {
                iOSCameraView(capturedImage: $capturedImage) { image in
                    // Handle image capture
                    self.isLoading = true // Show loading
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { // Simulate loading delay
                        self.isLoading = false
                        navigateToForm(with: image)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: 300)

                Button(action: {
                    isLoading = true // Show loading
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
            }
            .blur(radius: isLoading ? 5 : 0) // Blur background when loading

            if isLoading {
                ProgressView("Loading...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
            }
        }
        .navigationTitle("Scan")
        .navigationBarTitleDisplayMode(.inline)
    }

    // Function to capture a photo
    private func capturePhoto() {
        // Add the logic to call the camera capture function if necessary
    }

    // Navigate to FormView
    private func navigateToForm(with image: UIImage) {
        // Replace with your actual FormView implementation
        // Example: let formView = FormView(capturedImage: image)
    }
}

#if os(iOS)
struct iOSCameraView: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    var onCapture: (UIImage) -> Void // Capture callback

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        context.coordinator.setupCamera(in: viewController)
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    // Function to capture a photo
    func capturePhoto(context: Context) {
        let settings = AVCapturePhotoSettings()
        context.coordinator.photoOutput?.capturePhoto(with: settings, delegate: context.coordinator)
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
