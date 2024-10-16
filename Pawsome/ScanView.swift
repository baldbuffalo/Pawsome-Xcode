import SwiftUI
import UIKit

// ImagePicker struct for accessing the camera and photo library
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    var sourceType: UIImagePickerController.SourceType

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: ImagePicker

        init(parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.presentationMode.wrappedValue.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}

// VideoPicker struct for recording videos
struct VideoPicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: VideoPicker

        init(parent: VideoPicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            // Handle video selection or recording here
            parent.presentationMode.wrappedValue.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.mediaTypes = ["public.movie"]  // Only videos
        picker.cameraCaptureMode = .video
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}

struct ScanView: View {
    @State private var showCameraOptions = false
    @State private var showImagePicker = false
    @State private var showVideoPicker = false
    @State private var selectedImage: UIImage?
    @State private var videoURL: URL? // Add this if you plan to use it later
    @State private var navigateToForm = false

    var body: some View {
        VStack {
            if let selectedImage = selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 300)
                    .onTapGesture {
                        navigateToForm = true // Navigate to FormView when image is tapped
                    }
            } else {
                Text("No Image Selected")
                    .font(.headline)
            }

            // Button to open camera options (Image Picker or Video Picker)
            Button(action: {
                showCameraOptions.toggle() // Show the popup when the button is tapped
            }) {
                HStack {
                    Image(systemName: "camera")
                    Text("Open Camera Options")
                }
            }
            .buttonStyle(BorderlessButtonStyle())
            .actionSheet(isPresented: $showCameraOptions) {
                ActionSheet(
                    title: Text("Choose an Option"),
                    buttons: [
                        .default(Text("Take Photo")) {
                            showImagePicker = true
                        },
                        .default(Text("Record Video")) {
                            showVideoPicker = true
                        },
                        .default(Text("Choose from Library")) {
                            showImagePicker = true
                        },
                        .cancel()
                    ]
                )
            }

            NavigationLink(destination: FormView(showForm: $navigateToForm, imageUI: selectedImage, videoURL: videoURL, username: "YourUsername", onPostCreated: { post in
                // Handle the post created here
            }), isActive: $navigateToForm) {
                EmptyView() // Hidden navigation link to trigger navigation
            }

            Spacer()
        }
        .padding()
        // Present ImagePicker when the user selects "Take Photo" or "Choose from Library"
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage, sourceType: .photoLibrary) // You can change the source type based on the action
        }
        // Present VideoPicker when the user selects "Record Video"
        .sheet(isPresented: $showVideoPicker) {
            VideoPicker() // Implement handling for the recorded video as needed
        }
    }
}
