import SwiftUI
import AVFoundation

struct ScanView: View {
    @Binding var capturedImage: UIImage?
    @Binding var hideTabBar: Bool // To hide the tab bar during image capture

    var body: some View {
        CameraView(capturedImage: $capturedImage, hideTabBar: $hideTabBar)
            .edgesIgnoringSafeArea(.all)
            .onDisappear {
                // Ensure the tab bar is shown when leaving ScanView
                hideTabBar = false
            }
    }
}

struct CameraView: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    @Binding var hideTabBar: Bool // Binding to manage tab bar visibility

    func makeUIViewController(context: Context) -> CameraViewController {
        let cameraVC = CameraViewController(capturedImage: $capturedImage, hideTabBar: $hideTabBar)
        return cameraVC
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        // Update logic if needed
    }
}

class CameraViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    @Binding var capturedImage: UIImage?
    @Binding var hideTabBar: Bool // To hide the tab bar during image capture

    private var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?

    init(capturedImage: Binding<UIImage?>, hideTabBar: Binding<Bool>) {
        self._capturedImage = capturedImage
        self._hideTabBar = hideTabBar
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

        // Check for camera availability
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            print("No video capture device available")
            return
        }

        do {
            let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            if captureSession?.canAddInput(videoInput) == true {
                captureSession?.addInput(videoInput)
            } else {
                print("Could not add video input")
                return
            }
        } catch {
            print("Error initializing video input: \(error)")
            return
        }

        photoOutput = AVCapturePhotoOutput()
        if let photoOutput = photoOutput, captureSession?.canAddOutput(photoOutput) == true {
            captureSession?.addOutput(photoOutput)
        } else {
            print("Could not add photo output")
            return
        }

        // Setup the preview layer
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        captureSession?.startRunning()
        setupCaptureButton()
    }

    private func setupCaptureButton() {
        let captureButton = UIButton(frame: CGRect(x: view.frame.width - 90, y: view.frame.height - 90, width: 70, height: 70))
        captureButton.layer.cornerRadius = 35
        captureButton.backgroundColor = .blue
        captureButton.setTitle("Capture", for: .normal)
        captureButton.addTarget(self, action: #selector(captureImage), for: .touchUpInside)
        view.addSubview(captureButton)
    }

    @objc private func captureImage() {
        // Hide the tab bar when capturing the image
        hideTabBar = true

        let settings = AVCapturePhotoSettings()
        photoOutput?.capturePhoto(with: settings, delegate: self)
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation(), let image = UIImage(data: imageData) else { return }
        capturedImage = image // Set the captured image
        
        // Show the tab bar after capturing the image
        hideTabBar = false
    }
}
