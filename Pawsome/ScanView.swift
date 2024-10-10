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
    }

    // Function to capture the image programmatically, if needed
    func captureImage() {
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
}
