import SwiftUI
import AVFoundation

class ScanView: UIViewController, AVCapturePhotoCaptureDelegate {
    @Binding var capturedImage: UIImage?
    @Binding var catPosts: [CatPost]
    var currentUsername: String

    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var isCameraReady = false

    // Custom initializer for the class
    init(capturedImage: Binding<UIImage?>, catPosts: Binding<[CatPost]>, currentUsername: String) {
        self._capturedImage = capturedImage
        self._catPosts = catPosts
        self.currentUsername = currentUsername
        super.init(nibName: nil, bundle: nil) // Call the superclass initializer
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        startCamera()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopCamera()
    }

    var body: some View {
        VStack {
            // Placeholder for your camera view, since we can't use UIView directly here
            Text("Camera Preview will be here")
                .padding()

            Button(action: {
                // Explicitly reference 'self' when calling captureImage
                self.captureImage()
            }) {
                Text("Capture Cat Photo")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.bottom, 50)

            // Display the captured image if available
            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 300, maxHeight: 300)
                    .cornerRadius(10)
                    .padding()
            }

            Button(action: {
                // Handle done action
            }) {
                Text("Done")
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
        }
    }

    private func startCamera() {
        let session = AVCaptureSession()
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }

        if (session.canAddInput(videoInput)) {
            session.addInput(videoInput)
        } else {
            return
        }

        let videoOutput = AVCapturePhotoOutput()
        if (session.canAddOutput(videoOutput)) {
            session.addOutput(videoOutput)
        } else {
            return
        }

        // Set the session to be used in the preview layer
        captureSession = session
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        previewLayer?.videoGravity = .resizeAspectFill

        // Set preview layer frame
        DispatchQueue.main.async {
            if let previewLayer = self.previewLayer { // Explicitly use 'self'
                // Get the current window scene and set the preview layer
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    if let window = windowScene.windows.first {
                        previewLayer.frame = window.bounds
                        window.layer.addSublayer(previewLayer)
                    }
                }
            }
        }

        // Start the camera session
        captureSession?.startRunning()
        isCameraReady = true
    }

    private func stopCamera() {
        captureSession?.stopRunning()
        captureSession = nil
    }

    private func captureImage() {
        guard let captureOutput = captureSession?.outputs.first as? AVCapturePhotoOutput else { return }
        let settings = AVCapturePhotoSettings()
        captureOutput.capturePhoto(with: settings, delegate: self)
    }

    // MARK: - AVCapturePhotoCaptureDelegate
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto) {
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else { return }
        
        // Set the captured image
        capturedImage = image
    }
}
