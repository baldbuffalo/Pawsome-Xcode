import SwiftUI
import AVFoundation

struct ScanView: View {
    @Binding var capturedImage: UIImage?
    @Binding var hideTabBar: Bool // To hide the tab bar during image capture
    @State private var hideButtons: Bool = false // To hide buttons during capture

    var body: some View {
        ZStack {
            CameraView(capturedImage: $capturedImage, hideTabBar: $hideTabBar, hideButtons: $hideButtons)
                .edgesIgnoringSafeArea(.all)

            if !hideButtons {
                VStack {
                    Spacer()
                    // Add any additional buttons or UI elements here if needed
                }
            }
        }
        .onDisappear {
            // Ensure the tab bar is shown when leaving ScanView
            hideTabBar = false
            hideButtons = false // Show buttons when leaving
        }
    }
}

struct CameraView: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    @Binding var hideTabBar: Bool // Binding to manage tab bar visibility
    @Binding var hideButtons: Bool // Binding to manage buttons visibility

    func makeUIViewController(context: Context) -> CameraViewController {
        let cameraVC = CameraViewController(capturedImage: $capturedImage, hideTabBar: $hideTabBar, hideButtons: $hideButtons)
        return cameraVC
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        // Update logic if needed
    }
}

class CameraViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    @Binding var capturedImage: UIImage?
    @Binding var hideTabBar: Bool // To hide the tab bar during image capture
    @Binding var hideButtons: Bool // To hide buttons during image capture

    private var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?

    // Zoom factors
    private let maxZoomFactor: CGFloat = 5.0
    private var zoomFactor: CGFloat = 1.0 {
        didSet {
            updateZoom()
        }
    }

    init(capturedImage: Binding<UIImage?>, hideTabBar: Binding<Bool>, hideButtons: Binding<Bool>) {
        self._capturedImage = capturedImage
        self._hideTabBar = hideTabBar
        self._hideButtons = hideButtons
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        setupDoubleTapGesture()
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
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        videoPreviewLayer?.frame = view.layer.bounds
        videoPreviewLayer?.videoGravity = .resizeAspectFill
        view.layer.addSublayer(videoPreviewLayer!)

        captureSession?.startRunning()
    }

    private func setupDoubleTapGesture() {
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTapGesture.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTapGesture)
    }

    @objc private func handleDoubleTap() {
        captureImage()
    }

    private func captureImage() {
        // Hide the tab bar and buttons when capturing the image
        hideTabBar = true
        hideButtons = true

        let settings = AVCapturePhotoSettings()
        photoOutput?.capturePhoto(with: settings, delegate: self)
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation(), let image = UIImage(data: imageData) else { return }
        capturedImage = image // Set the captured image
        
        // Show the tab bar and buttons after capturing the image
        hideTabBar = false
        hideButtons = false
    }

    private func updateZoom() {
        guard let videoDevice = AVCaptureDevice.default(for: .video) else { return }
        do {
            try videoDevice.lockForConfiguration()
            videoDevice.videoZoomFactor = zoomFactor
            videoDevice.unlockForConfiguration()
        } catch {
            print("Error setting zoom: \(error)")
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Handle touch for zooming
        guard let touch = touches.first else { return }
        let touchLocation = touch.location(in: view)

        // Calculate zoom factor based on touch location
        let width = view.bounds.width
        let height = view.bounds.height
        let x = touchLocation.x / width
        let y = touchLocation.y / height

        if zoomFactor < maxZoomFactor {
            zoomFactor += 1.0 // Increase zoom factor (can adjust this increment)
        } else {
            zoomFactor = 1.0 // Reset zoom factor to 1.0
        }

        updateZoom()
    }
}
