import SwiftUI
import AVFoundation

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// Scan View for capturing images
struct ScanView: View {
    @StateObject private var scanner = CatScanner()

    var body: some View {
        ZStack {
            // Camera View
            #if os(iOS)
            CameraView(scanner: scanner)
                .edgesIgnoringSafeArea(.all) // Extend camera view to edges
            #else
            // Placeholder for macOS
            Text("Camera is not available on this platform.")
                .font(.largeTitle)
                .foregroundColor(.gray)
            #endif
            
            // Overlay (Optional)
            Color.black.opacity(0.3) // Semi-transparent overlay for effect
            
            VStack {
                Spacer()
                Button(action: {
                    scanner.captureImage() // Capture image when the button is pressed
                }) {
                    Text("Capture Image")
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding()
            }
        }
    }
}

// Custom Camera View using UIViewControllerRepresentable for iOS
#if os(iOS)
struct CameraView: UIViewControllerRepresentable {
    @ObservedObject var scanner: CatScanner

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        scanner.setupCamera(view: viewController.view) // Set up camera with the view

        // Return the view controller
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No need to update the view controller in this simple implementation
    }
}
#endif

// Class for capturing images
class CatScanner: NSObject, AVCapturePhotoCaptureDelegate, ObservableObject {
    private var captureSession: AVCaptureSession
    private var photoOutput: AVCapturePhotoOutput
    #if os(iOS)
    var previewLayer: AVCaptureVideoPreviewLayer
    #endif

    override init() {
        captureSession = AVCaptureSession()
        photoOutput = AVCapturePhotoOutput()
        #if os(iOS)
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        #endif
        super.init()
    }

    #if os(iOS)
    func setupCamera(view: UIView) {
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }

        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            return
        }

        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        } else {
            return
        }

        // Setup the preview layer
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.layer.bounds
        view.layer.addSublayer(previewLayer) // Add preview layer to the view

        startScanning() // Start the camera session
    }
    #endif

    func startScanning() {
        captureSession.startRunning() // Start camera session
    }

    func stopScanning() {
        captureSession.stopRunning() // Stop camera session
    }

    func captureImage() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self) // Capture photo
    }

    // Delegate method to handle the captured image
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto) {
        guard let imageData = photo.fileDataRepresentation() else { return }
        
        #if os(iOS)
        let image = UIImage(data: imageData)
        // Notify about the captured image
        print("Captured image: \(String(describing: image))") // Handle the captured image as needed
        #endif
    }
}

// Preview for ScanView
struct ScanView_Previews: PreviewProvider {
    static var previews: some View {
        ScanView()
            .previewLayout(.sizeThatFits)
    }
}
