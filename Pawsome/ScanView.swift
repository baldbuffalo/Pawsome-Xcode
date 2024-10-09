import SwiftUI
import AVFoundation

// Define a protocol for camera capturing
protocol CameraViewDelegate {
    func didTapCapture()
}

struct ScanView: View, CameraViewDelegate {
    @Binding var capturedImage: UIImage? // Expecting capturedImage as a binding
    @Binding var catPosts: [CatPost] // Expecting catPosts as a binding
    @State private var isLoading = false
    @State private var isNavigatingToForm = false
    @State private var coordinator: CameraView.Coordinator?

    var body: some View {
        NavigationStack {
            ZStack {
                // Pass the capturedImage binding and other parameters to CameraView
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
                        capturePhoto()
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
                FormView(catPosts: $catPosts, imageUI: capturedImage) // Passing image to the FormView
            }
        }
    }

    private func capturePhoto() {
        isLoading = true
        coordinator?.captureImage()
    }

    func didTapCapture() {
        isLoading = false
        isNavigatingToForm = true
    }
}

struct CameraView: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    var delegate: CameraViewDelegate?
    @Binding var coordinatorBinding: Coordinator?

    func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator(self)
        DispatchQueue.main.async {
            self.coordinatorBinding = coordinator
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
        var previewLayer: AVCaptureVideoPreviewLayer?

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

            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer?.videoGravity = .resizeAspectFill
            previewLayer?.frame = viewController.view.bounds
            viewController.view.layer.addSublayer(previewLayer!)

            captureSession.startRunning()
        }

        func captureImage() {
            let settings = AVCapturePhotoSettings()
            photoOutput?.capturePhoto(with: settings, delegate: self)

            previewLayer?.connection?.isEnabled = false
        }

        func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
            DispatchQueue.main.async {
                self.parent.capturedImage = nil
                if let data = photo.fileDataRepresentation(), let image = UIImage(data: data) {
                    self.parent.capturedImage = image
                    self.parent.delegate?.didTapCapture()
                    self.previewLayer?.connection?.isEnabled = true
                } else {
                    print("Failed to capture image.")
                    self.previewLayer?.connection?.isEnabled = true
                }
            }
        }
    }
}
