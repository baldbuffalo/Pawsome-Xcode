import SwiftUI
import AVFoundation

// Define a protocol for camera capturing
protocol CameraViewDelegate {
    func didTapCapture()
}

struct ScanView: View, CameraViewDelegate {
    @State private var capturedImage: UIImage?
    @State private var isLoading = false
    @State private var isNavigatingToForm = false
    @State private var coordinator: CameraView.Coordinator? // Store coordinator reference

    var body: some View {
        NavigationStack {
            ZStack {
                // Bind coordinator and pass delegate
                CameraView(capturedImage: $capturedImage, delegate: self, coordinatorBinding: $coordinator)
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
                Form(imageUI: capturedImage) // Pass captured image to the form
            }
        }
    }

    private func capturePhoto() {
        isLoading = true // Show loading indicator
        // Trigger photo capture through the coordinator
        coordinator?.captureImage()
    }

    // Implement the delegate method
    func didTapCapture() {
        isLoading = false // Hide loading indicator
        isNavigatingToForm = true // Navigate to FormView
    }
}

struct CameraView: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    var delegate: CameraViewDelegate? // Add delegate
    @Binding var coordinatorBinding: Coordinator? // Bind coordinator to ScanView

    func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator(self)
        DispatchQueue.main.async {
            self.coordinatorBinding = coordinator // Bind the coordinator
        }
        return coordinator
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

        func captureImage() {
            let settings = AVCapturePhotoSettings()
            photoOutput?.capturePhoto(with: settings, delegate: self) // Capture the photo
        }

        // Process the captured photo
        func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
            DispatchQueue.main.async {
                self.parent.capturedImage = nil // Reset the captured image
                if let data = photo.fileDataRepresentation(), let image = UIImage(data: data) {
                    self.parent.capturedImage = image // Assign the captured image
                    // Call the delegate to notify the scan view
                    self.parent.delegate?.didTapCapture()
                } else {
                    print("Failed to capture image.")
                }
            }
        }
    }
}
#if os(iOS) || os(tvOS) || targetEnvironment(macCatalyst)
import SwiftUI
#endif
