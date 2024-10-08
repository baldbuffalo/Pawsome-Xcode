import SwiftUI
import AVFoundation

struct ScanView: View {
    @State private var capturedImage: UIImage?
    @State private var isLoading = false
    @State private var isNavigatingToForm = false

    var body: some View {
        NavigationStack {
            ZStack {
                CameraView(capturedImage: $capturedImage) { image in
                    // Handle the captured image here if needed
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
                    .blur(radius: isLoading ? 5 : 0)
                }
            }
            .navigationTitle("Scan")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $isNavigatingToForm) {
                FormView(imageUI: capturedImage) // Pass captured image to the form
            }
        }
    }

    private func capturePhoto() {
        isLoading = true // Show loading indicator

        // Simulate photo capture delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isLoading = false // Hide loading indicator
            isNavigatingToForm = true // Navigate to FormView
        }
    }

    struct CameraView: UIViewControllerRepresentable {
        @Binding var capturedImage: UIImage?
        var onCapture: (UIImage) -> Void

        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }

        func makeUIViewController(context: Context) -> UIViewController {
            let viewController = UIViewController()
            context.coordinator.setupCamera(in: viewController)
            return viewController
        }

        func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

        class Coordinator: NSObject, AVCapturePhotoCaptureDelegate {
            var parent: CameraView
            var captureSession: AVCaptureSession?
            var photoOutput: AVCapturePhotoOutput?

            init(_ parent: CameraView) {
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

            // Process the captured photo
            func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
                if let data = photo.fileDataRepresentation(), let image = UIImage(data: data) {
                    parent.onCapture(image) // Call the onCapture closure with the captured image
                } else {
                    parent.capturedImage = nil
                }
            }
        }
    }
}
