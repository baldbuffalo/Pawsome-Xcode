import SwiftUI
import AVFoundation

struct ScanView: View {
    @Binding var capturedImage: UIImage?
    @Binding var hideTabBar: Bool // To hide the tab bar during image capture

    var body: some View {
        ZStack {
            CameraView(capturedImage: $capturedImage, hideTabBar: $hideTabBar)
                .edgesIgnoringSafeArea(.all)

            VStack {
                Spacer()
                // Camera capture button
                Button(action: {
                    // Action to capture image
                    hideTabBar = true
                }) {
                    Image(systemName: "camera.fill")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .padding()
                        .background(Color.white.opacity(0.7))
                        .clipShape(Circle())
                        .shadow(radius: 5)
                }
                .padding(.bottom, 30) // Position it above the bottom
            }
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
    private let maxZoomFactor: CGFloat = 5.0
    private var zoomFactor: CGFloat = 1.0 {
        didSet {
            updateZoom()
        }
    }

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
        setupGestureRecognizers()
    }

    private func setupGestureRecognizers() {
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(captureImage))
        doubleTapGesture.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTapGesture)

        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(zoomCamera(_:)))
        view.addGestureRecognizer(pinchGesture)
    }

    @objc private func zoomCamera(_ sender: UIPinchGestureRecognizer) {
        if sender.state == .changed {
            zoomFactor *= sender.scale
            sender.scale = 1.0
        }
    }

    @objc private func captureImage() {
        // Hide the tab bar when capturing the image
        hideTabBar = true

        let settings = AVCapturePhotoSettings()
        photoOutput?.capturePhoto(with: settings, delegate: self)
    }

    private func updateZoom() {
        guard let device = AVCaptureDevice.default(for: .video) else { return }

        do {
            try device.lockForConfiguration()
            device.videoZoomFactor = zoomFactor
            device.unlockForConfiguration()
        } catch {
            print("Error setting zoom: \(error)")
        }
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else { return }
        
        capturedImage = image // Set the captured image
        hideTabBar = false // Show the tab bar after capturing the image
    }
}
