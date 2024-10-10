import SwiftUI
import AVFoundation

struct ScanView: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    var currentUsername: String

    func makeUIViewController(context: Context) -> CameraViewController {
        let cameraViewController = CameraViewController(capturedImage: $capturedImage, currentUsername: currentUsername)
        return cameraViewController
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        // Update the view controller as needed
    }
}

class CameraViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    @Binding var capturedImage: UIImage?
    var currentUsername: String

    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var isCameraReady = false

    init(capturedImage: Binding<UIImage?>, currentUsername: String) {
        self._capturedImage = capturedImage
        self.currentUsername = currentUsername
        super.init(nibName: nil, bundle: nil) // Call the superclass initializer
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        startCamera()
        setupCaptureButton()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopCamera()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Update the previewLayer's frame to fit the view's bounds minus the height of the bottom bar
        let bottomBarHeight: CGFloat = 80 // Adjust this value based on your bottom bar height
        previewLayer?.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height - bottomBarHeight)
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

        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        } else {
            return
        }

        let videoOutput = AVCapturePhotoOutput()
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        } else {
            return
        }

        captureSession = session
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        previewLayer?.videoGravity = .resizeAspectFill

        // Add the preview layer to the view
        DispatchQueue.main.async {
            if let previewLayer = self.previewLayer {
                previewLayer.frame = CGRect(x: 0, y: 0, width: self.view.layer.bounds.width, height: self.view.layer.bounds.height - 80) // Update to include bottom bar height
                self.view.layer.addSublayer(previewLayer)
            }
        }

        captureSession?.startRunning()
        isCameraReady = true
    }

    private func stopCamera() {
        captureSession?.stopRunning()
        captureSession = nil
    }

    private func setupCaptureButton() {
        let buttonHeight: CGFloat = 70
        let buttonWidth: CGFloat = 70

        // Center the button horizontally and place it at the bottom middle of the preview
        let buttonYPosition = self.view.frame.height - buttonHeight - 20 // 20 points above the bottom edge

        let captureButton = UIButton(frame: CGRect(x: (self.view.frame.width - buttonWidth) / 2,
                                                   y: buttonYPosition,
                                                   width: buttonWidth,
                                                   height: buttonHeight))

        captureButton.setTitle("📸", for: .normal) // Set an icon to make it visually appealing
        captureButton.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        captureButton.layer.cornerRadius = buttonHeight / 2  // Make it a circular button
        captureButton.clipsToBounds = true
        captureButton.addTarget(self, action: #selector(captureImage), for: .touchUpInside)

        self.view.addSubview(captureButton)
    }

    @objc private func captureImage() {
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
