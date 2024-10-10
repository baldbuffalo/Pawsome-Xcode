import SwiftUI
import AVFoundation

struct ScanView: View {
    @State private var capturedImage: UIImage?
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
                    // The CameraView will handle the image capture
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

class CameraViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    @Binding var capturedImage: UIImage?
    var onCapture: () -> Void // Closure to call when image is captured

    private var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?

    init(capturedImage: Binding<UIImage?>, onCapture: @escaping () -> Void) {
        self._capturedImage = capturedImage
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

    @objc func captureImage() {
        let settings = AVCapturePhotoSettings()
        photoOutput?.capturePhoto(with: settings, delegate: self)
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else { return }
        
        capturedImage = image // Set the captured image
        onCapture() // Call the capture closure
    }
}
