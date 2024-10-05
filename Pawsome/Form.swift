import SwiftUI
import AVFoundation

struct ScanView: View {
    @State private var capturedImage: UIImage?
    @State private var isLoading = false
    @State private var isNavigating = false // State to control navigation

    var body: some View {
        ZStack {
            // Full screen camera preview
            CustomCameraView(capturedImage: $capturedImage) { image in
                // Handle image capture
                self.isLoading = true // Show loading
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { // Simulate loading delay
                    self.isLoading = false
                    self.capturedImage = image // Set the captured image
                    self.isNavigating = true // Trigger navigation
                }
            }
            .edgesIgnoringSafeArea(.all) // Extend to full screen

            // Capture button
            VStack {
                Spacer()
                Button(action: {
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
                .padding(.bottom, 20) // Add padding to the bottom
            }

            // Loading indicator
            if isLoading {
                ProgressView("Loading...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
            }
        }
        .navigationTitle("Scan")
        .navigationBarTitleDisplayMode(.inline)
        .background(
            NavigationLink(destination: FormView(imageUI: capturedImage), isActive: $isNavigating) {
                EmptyView()
            }
        )
    }

    // Function to capture a photo
    private func capturePhoto() {
        // Call the camera capture function if necessary
    }
}

#if os(iOS)
struct CustomCameraView: UIViewControllerRepresentable {
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
        var parent: CustomCameraView
        var captureSession: AVCaptureSession?
        var photoOutput: AVCapturePhotoOutput?

        init(_ parent: CustomCameraView) {
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
