import SwiftUI
import AVFoundation

struct ScanView: View {
    @Binding var capturedImage: UIImage?
    var currentUsername: String
    @Binding var hideTabBar: Bool
    
    @State private var captureSession: AVCaptureSession?
    @State private var photoOutput: AVCapturePhotoOutput?
    
    var body: some View {
        ZStack {
            CameraPreview(session: captureSession)
                .onAppear {
                    setupCamera()
                }
                .onDisappear {
                    captureSession?.stopRunning()
                }
            
            VStack {
                Spacer()
                captureButton
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    private var captureButton: some View {
        Button(action: {
            hideTabBar = true // Hide the tab bar when capturing the image
            captureImage()
        }) {
            Text("Capture")
                .font(.headline)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.bottom, 30)
        }
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

        captureSession?.startRunning()
    }
    
    private func captureImage() {
        guard let output = photoOutput else { return }
        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: makeCoordinator())
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    class Coordinator: NSObject, AVCapturePhotoCaptureDelegate {
        var parent: ScanView
        
        init(_ parent: ScanView) {
            self.parent = parent
        }
        
        func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
            guard let imageData = photo.fileDataRepresentation() else { return }
            let image = UIImage(data: imageData)
            parent.capturedImage = image // Set the captured image
            parent.hideTabBar = false // Show the tab bar after capturing the image
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    var session: AVCaptureSession?

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let previewLayer = AVCaptureVideoPreviewLayer(session: session!)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let session = session {
            let previewLayer = uiView.layer.sublayers?.compactMap { $0 as? AVCaptureVideoPreviewLayer }.first
            previewLayer?.session = session
            previewLayer?.frame = uiView.layer.bounds
        }
    }
}
