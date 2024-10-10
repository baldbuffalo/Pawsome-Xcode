import SwiftUI
import AVFoundation

struct ScanView: View {
    @Binding var capturedImage: UIImage? // Bind the captured image from HomeView
    @Binding var hideTabBar: Bool // Bind to control the tab bar visibility
    @State private var showEditView = false // State to control the presentation of the edit view

    var body: some View {
        ZStack {
            CameraView(capturedImage: $capturedImage, onCapture: {
                showEditView = true // Show the editing view after capturing the image
            })
            .edgesIgnoringSafeArea(.all)

            VStack {
                Spacer()
                // Camera capture button
                Button(action: {
                    NotificationCenter.default.post(name: Notification.Name("captureImage"), object: nil) // Trigger capture
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
        .onAppear {
            hideTabBar = true // Hide the tab bar when ScanView appears
        }
        .onDisappear {
            hideTabBar = false // Show the tab bar again when ScanView disappears
        }
        .fullScreenCover(isPresented: $showEditView) {
            if let capturedImage = capturedImage {
                ImageEditing(image: capturedImage) // Present the ImageEditing view
            }
        }
    }
}

struct CameraView: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    var onCapture: () -> Void // Closure to call when the image is captured

    func makeUIViewController(context: Context) -> CameraViewController {
        let cameraVC = CameraViewController(capturedImage: $capturedImage, onCapture: onCapture)
        return cameraVC
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        // Update logic if needed
    }
}

class CameraViewController: UIViewController {
    @Binding var capturedImage: UIImage?
    var onCapture: () -> Void // Closure to call when the image is captured

    private var captureSession: AVCaptureSession!
    private var photoOutput: AVCapturePhotoOutput!
    private var previewLayer: AVCaptureVideoPreviewLayer!

    init(capturedImage: Binding<UIImage?>, onCapture: @escaping () -> Void) {
        _capturedImage = capturedImage
        self.onCapture = onCapture
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

        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            return
        }

        photoOutput = AVCapturePhotoOutput()
        if (captureSession.canAddOutput(photoOutput)) {
            captureSession.addOutput(photoOutput)
        } else {
            return
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        captureSession.startRunning()

        NotificationCenter.default.addObserver(self, selector: #selector(captureImage), name: Notification.Name("captureImage"), object: nil)
    }

    @objc private func captureImage() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession.stopRunning()
        NotificationCenter.default.removeObserver(self)
    }
}

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation() else { return }
        capturedImage = UIImage(data: imageData)
        onCapture() // Call the closure to indicate that an image has been captured
    }
}
