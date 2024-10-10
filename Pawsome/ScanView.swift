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
            if let session = captureSession {
                CameraPreview(session: session)
                    .onAppear {
                        setupCamera()
                    }
                    .onDisappear {
                        session.stopRunning()
                    }
            } else {
                Text("No Camera Available") // Show a placeholder if the camera session is not available
                    .foregroundColor(.red)
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
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            print("No video capture device available")
            return
        }
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            print("Error initializing video input: \(error)")
            return
        }

        if (captureSession?.canAddInput(videoInput) == true) {
            captureSession?.addInput(videoInput)
        } else {
            print("Could not add video input")
            return
        }

        photoOutput = AVCapturePhotoOutput()
        if let photoOutput = photoOutput, captureSession?.canAddOutput(photoOutput) == true {
            captureSession?.addOutput(photoOutput)
        } else {
            print("Could not add photo output")
            return
        }

        captureSession?.startRunning()
    }
    
    private func captureImage() {
        guard let output = photoOutput else {
            print("Photo output is not available")
            return
        }
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
            if let error = error {
                print("Error capturing photo: \(error)")
                return
            }
            guard let imageData = photo.fileDataRepresentation(),
                  let image = UIImage(data: imageData) else {
                print("Error converting photo data to image")
                return
            }
            parent.capturedImage = image // Set the captured image
            parent.hideTabBar = false // Show the tab bar after capturing the image
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    var session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        let previewLayer = uiView.layer.sublayers?.compactMap { $0 as? AVCaptureVideoPreviewLayer }.first
        previewLayer?.session = session
        previewLayer?.frame = uiView.layer.bounds
    }
}
