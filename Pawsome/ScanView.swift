import SwiftUI
import AVFoundation

struct ScanView: View {
    @Binding var capturedImage: UIImage? // Binding to capture image
    @Binding var hideTabBar: Bool // Binding to control tab bar visibility
    @Binding var catPosts: [CatPost] // Binding to an array of CatPost

    var body: some View {
        VStack {
            Text("Taking a picture of your cat")
                .font(.headline)
                .padding()

            Button("Open Camera") {
                openCamera()
            }
            .padding()
        }
        .navigationTitle("Scan Cat")
        // Using the updated onChange syntax
        .onChange(of: capturedImage) { newImage in
            guard let image = newImage else { return }
            navigateToForm(with: image)
        }
    }

    private func openCamera() {
        // Access the current scene
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let topController = windowScene.windows.first?.rootViewController else {
            return
        }

        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.delegate = makeCoordinator() // Set the coordinator as delegate
        topController.present(imagePicker, animated: true)
    }

    private func navigateToForm(with image: UIImage) {
        let newCatPost = CatPost(id: UUID(), name: "", breed: "", age: "", imageData: image.jpegData(compressionQuality: 1.0), username: "", creationTime: Date(), likes: 0, comments: [])
        
        // Add the new post to the array
        catPosts.append(newCatPost)
        hideTabBar = true // Hide the tab bar if needed
        
        // Navigate to FormView
        // This part will depend on how you are managing your navigation.
        // If you're using NavigationLink or programmatic navigation, add that logic here.
    }

    // Coordinator to handle UIImagePickerController delegate
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
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
