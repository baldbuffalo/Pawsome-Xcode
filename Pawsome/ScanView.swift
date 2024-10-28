import SwiftUI
import CoreData

struct ScanView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var imageUI: UIImage?
    @State private var showingImagePicker = false
    @State private var mediaType: UIImagePickerController.SourceType? = nil
    @State private var showMediaTypeSelection = false
    @Binding var showForm: Bool
    @Binding var selectedImage: UIImage? // Binding to hold the selected image
    var username: String

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .cornerRadius(10)
                } else {
                    Text("No image selected.")
                        .foregroundColor(.gray)
                }
                
                Button("Select Image") {
                    showMediaTypeSelection = true
                }
                .actionSheet(isPresented: $showMediaTypeSelection) {
                    ActionSheet(
                        title: Text("Choose Media Type"),
                        buttons: [
                            .default(Text("Camera")) {
                                mediaType = .camera
                                showingImagePicker = true
                            },
                            .default(Text("Photo Library")) {
                                mediaType = .photoLibrary
                                showingImagePicker = true
                            },
                            .cancel()
                        ]
                    )
                }
                .sheet(isPresented: $showingImagePicker) {
                    if let mediaType = mediaType {
                        ImagePicker(sourceType: mediaType, selectedImage: $imageUI) { image in
                            selectedImage = image
                            navigateToForm()
                        }
                    }
                }
            }
            .navigationTitle("Scan View")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showForm) {
                FormView(
                    showForm: $showForm,
                    navigateToHome: .constant(false),
                    imageUI: selectedImage,  // Pass the selected image here
                    videoURL: nil,
                    username: username,
                    onPostCreated: { _ in },
                    catPost: .constant(CatPost(context: viewContext))
                )
            }
        }
    }

    private func navigateToForm() {
        showForm = true
    }
}
