import SwiftUI
import AVFoundation

struct ScanView: View {
    @Binding var capturedImage: UIImage? // Binding to capture image
    @Binding var hideTabBar: Bool // Binding to control tab bar visibility

    // AVFoundation variables
    @State private var captureSession = AVCaptureSession()
    @State private var isCameraReady = false

    var body: some View {
        VStack {
            CameraPreview(session: captureSession) // Custom camera preview
                .onAppear {
                    checkCameraAuthorization()
                    setupCamera()
                }
                .onDisappear {
                    captureSession.stopRunning() // Stop the session when view disappears
                }

            Button("Capture") {
                captureImage()
            }
            .padding()
        }
        // Using the new syntax for onChange
        .onChange(of: isCameraReady) {
            if isCameraReady { // Check the new state directly
                captureSession.startRunning()
            }
        }
        .navigationTitle("Scan Cat")
    }

    private func checkCameraAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isCameraReady = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    isCameraReady = granted
                }
            }
        default:
            break
        }
    }

    private func setupCamera() {
        guard isCameraReady else { return }

        // Setup camera input and output
        guard let videoDevice = AVCaptureDevice.default(for: .video) else {
            print("No video device available")
            return
        }

        do {
            let videoInput = try AVCaptureDeviceInput(device: videoDevice)
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            } else {
                print("Cannot add video input")
            }

            // Setup video output
            let videoOutput = AVCapturePhotoOutput()
            if captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
            } else {
                print("Cannot add video output")
            }

        } catch {
            print("Error setting up camera: \(error)")
        }
    }

    private func captureImage() {
        guard let photoOutput = captureSession.outputs.first as? AVCapturePhotoOutput else { return }
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: PhotoCaptureDelegate { image in
            self.capturedImage = image
        })
    }
}

// A struct for your camera preview layer
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = uiView.bounds // Update the preview layer frame to match the view
        }
    }
}

// Photo capture delegate
class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    var completion: ((UIImage?) -> Void)

    init(completion: @escaping (UIImage?) -> Void) {
        self.completion = completion
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto) {
        if let imageData = photo.fileDataRepresentation(),
           let image = UIImage(data: imageData) {
            completion(image)
        } else {
            completion(nil)
        }
    }
}
