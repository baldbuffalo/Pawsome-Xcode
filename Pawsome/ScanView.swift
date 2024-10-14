import SwiftUI
import AVFoundation

struct ScanView: View {
    @Binding var capturedImage: UIImage?
    @Binding var hideTabBar: Bool // Binding to control the visibility of the tab bar
    
    var body: some View {
        ZStack {
            CameraPreview(capturedImage: $capturedImage)
                .edgesIgnoringSafeArea(.all) // Fill the entire screen

            VStack {
                Spacer() // Pushes the capture button to the bottom

                Button(action: {
                    captureImage()
                }) {
                    Text("Capture Image")
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.bottom, 40) // Padding from the bottom
            }
        }
        .onAppear {
            hideTabBar = true // Hide the tab bar when the Scan view appears
        }
        .onDisappear {
            hideTabBar = false // Show the tab bar again when leaving the Scan view
        }
    }

    private func captureImage() {
        // Notify the CameraPreview to capture the photo
        NotificationCenter.default.post(name: NSNotification.Name("capturePhoto"), object: nil)
        print("Capture button tapped")
    }
}

// UIViewRepresentable for Camera Preview
struct CameraPreview: UIViewRepresentable {
    @Binding var capturedImage: UIImage?
    let captureSession = AVCaptureSession() // Accessible now
    var videoOutput: AVCapturePhotoOutput? // Accessible now

    init(capturedImage: Binding<UIImage?>) {
        self._capturedImage = capturedImage
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()

        // Set up camera input
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return view }
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return view
        }

        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            return view
        }

        // Set up photo output
        videoOutput = AVCapturePhotoOutput()
        if captureSession.canAddOutput(videoOutput!) {
            captureSession.addOutput(videoOutput!)
        }

        // Set up preview layer
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        // Start camera session
        captureSession.startRunning()

        // Capture photo when notification is posted
        NotificationCenter.default.addObserver(forName: NSNotification.Name("capturePhoto"), object: nil, queue: .main) { [weak self] _ in
            self?.capturePhoto(context: context)
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Update the UIView if needed
    }

    func capturePhoto(context: Context) {
        let settings = AVCapturePhotoSettings()
        videoOutput?.capturePhoto(with: settings, delegate: context.coordinator)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // Coordinator to handle the photo capturing
    class Coordinator: NSObject, AVCapturePhotoCaptureDelegate {
        var parent: CameraPreview

        init(_ parent: CameraPreview) {
            self.parent = parent
        }

        func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
            guard let imageData = photo.fileDataRepresentation(), error == nil else {
                print("Error capturing photo: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            // Convert the image data to a UIImage and assign it to the binding
            let image = UIImage(data: imageData)
            parent.capturedImage = image
        }
    }
}
