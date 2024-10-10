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

        DispatchQueue.main.async {
            if let previewLayer = self.previewLayer {
                previewLayer.frame = self.view.layer.bounds
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
        let captureButton = UIButton(frame: CGRect(x: (self.view.frame.width - 100) / 2, y: self.view.frame.height - 100, width: 100, height: 50))
        captureButton.setTitle("Capture", for: .normal)
        captureButton.backgroundColor = .blue
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
