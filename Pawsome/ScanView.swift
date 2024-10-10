import SwiftUI
import AVFoundation

struct ScanView: View, CameraViewDelegate {
    @Binding var capturedImage: UIImage?
    @Binding var catPosts: [CatPost]
    @State private var isLoading = false
    @State private var isNavigatingToForm = false
    @State private var coordinator: CameraView.Coordinator?
    private var postStorage = PostStorage() // Instance to load posts

    init(capturedImage: Binding<UIImage?>, catPosts: Binding<[CatPost]>) {
        _capturedImage = capturedImage
        _catPosts = catPosts
        loadPosts() // Load posts when initializing
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CameraView(capturedImage: $capturedImage, delegate: self, coordinatorBinding: $coordinator)
                    .edgesIgnoringSafeArea(.all)

                if isLoading {
                    ProgressView("Loading...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                        .background(Color.white.opacity(0.7))
                        .cornerRadius(10)
                }

                VStack {
                    Spacer()
                    Button(action: {
                        capturePhoto()
                    }) {
                        Text("Capture Image")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding()
                    .blur(radius: isLoading ? 5 : 0)
                }
            }
            .navigationTitle("Scan")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $isNavigatingToForm) {
                FormView(catPosts: $catPosts, imageUI: capturedImage)
            }
        }
    }

    private func loadPosts() {
        catPosts = postStorage.loadPosts() // Load posts when initializing
    }

    private func capturePhoto() {
        isLoading = true
        coordinator?.captureImage()
    }

    func didTapCapture() {
        isLoading = false
        isNavigatingToForm = true
    }
}
