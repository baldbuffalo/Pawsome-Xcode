import SwiftUI
import AVFoundation

struct ScanView: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    var currentUsername: String
    @Binding var hideTabBar: Bool // New binding to manage tab bar visibility

    func makeUIViewController(context: Context) -> CameraViewController {
        let cameraViewController = CameraViewController(capturedImage: $capturedImage, currentUsername: currentUsername, hideTabBar: $hideTabBar) // Pass the hideTabBar binding
        return cameraViewController
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        // Update the view controller as needed
    }
}

class CameraViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    @Binding var capturedImage: UIImage?
    var currentUsername: String
    @Binding var hideTabBar: Bool // Add binding to manage tab bar visibility

    private var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?

    init(capturedImage: Binding<UIImage?>, currentUsername: String, hideTabBar: Binding<Bool>) {
        self._capturedImage = capturedImage
        self.currentUsername = currentUsername
        self._hideTabBar = hideTabBar // Initialize the hideTabBar binding
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }

    private func setupCamera() {
        captureSession = AVCaptureSession()
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }

        if (captureSession?.canAddInput(videoInput) == true) {
            captureSession?.addInput(videoInput)
        } else {
            return
        }

        photoOutput = AVCapturePhotoOutput()
        if (captureSession?.canAddOutput(photoOutput!) == true) {
            captureSession?.addOutput(photoOutput!)
        } else {
            return
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        captureSession?.startRunning()

        setupCaptureButton()
    }

    private func setupCaptureButton() {
        let captureButton = UIButton(frame: CGRect(x: (view.frame.width - 70) / 2, y: view.frame.height - 100, width: 70, height: 70))
        captureButton.layer.cornerRadius = 35
        captureButton.backgroundColor = .blue
        captureButton.setTitle("Capture", for: .normal)
        captureButton.addTarget(self, action: #selector(captureImage), for: .touchUpInside)
        view.addSubview(captureButton)
    }

    @objc private func captureImage() {
        // Hide the tab bar when capturing the image
        hideTabBar = true // Directly modify the binding

        let settings = AVCapturePhotoSettings()
        photoOutput?.capturePhoto(with: settings, delegate: self)
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation() else { return }
        let image = UIImage(data: imageData)
        capturedImage = image // Set the captured image
        // Handle image editing or other actions here
    }
}
