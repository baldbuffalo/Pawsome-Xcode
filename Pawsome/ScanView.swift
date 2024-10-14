import SwiftUI
import AVFoundation

struct ScanView: View {
    @Binding var capturedImage: UIImage? // Binding to capture image
    @Binding var hideTabBar: Bool // Binding to control tab bar visibility
    @Binding var catPosts: [CatPost] // Binding to an array of CatPost
    @State private var isNavigating = false // State to trigger navigation
    @State private var showEditingView = false // State to control visibility of ImageEditing
    @State private var fileURL: URL? // Store the URL of the saved file

    var body: some View {
        NavigationStack {
            VStack {
                Text("Take a Picture of Your Cat")
                    .font(.headline)
                    .padding()

                Button("Open Camera") {
                    openCamera()
                }
                .padding()
            }
            .navigationTitle("Scan Cat")
            .onChange(of: capturedImage) {
                if let image = capturedImage {
                    saveImageToFile(image)
                }
            }
            // Use the new `navigationDestination` for programmatic navigation
            .navigationDestination(isPresented: $showEditingView) {
                ImageEditing(capturedImage: $capturedImage, catPosts: $catPosts, hideTabBar: $hideTabBar)
            }
        }
    }

    private func openCamera() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let topController = windowScene.windows.first?.rootViewController else {
            return
        }

        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.delegate = makeCoordinator() // Set the coordinator as delegate
        topController.present(imagePicker, animated: true)
    }

    private func saveImageToFile(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 1.0) else {
            print("Failed to convert image to JPEG data")
            return
        }

        let fileManager = FileManager.default
        let directory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName = "form.swift"
        let fileURL = directory.appendingPathComponent(fileName)

        do {
            try imageData.write(to: fileURL)
            self.fileURL = fileURL
            print("Image saved to file at: \(fileURL)")
            openFile(fileURL)
        } catch {
            print("Error saving image to file: \(error.localizedDescription)")
        }
    }

    private func openFile(_ url: URL) {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.item], asCopy: true)
        documentPicker.delegate = makeCoordinator() as? UIDocumentPickerDelegate
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let topController = windowScene.windows.first?.rootViewController else {
            return
        }
        topController.present(documentPicker, animated: true)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: ScanView

        init(_ parent: ScanView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.capturedImage = image // Set the captured image
                parent.saveImageToFile(image) // Save image to file
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
