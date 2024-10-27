import SwiftUI
import CoreData

@main
struct PawsomeApp: App {
    @State private var isLoggedIn: Bool = false
    @State private var username: String = ""
    @State private var profileImageData: Data? = nil // Use Data to store image
    @State private var capturedImage: UIImage? = nil
    @State private var videoURL: URL? = nil
    @State private var showForm: Bool = false // For form visibility
    @State private var navigateToHome: Bool = false // For navigation

    // Shared PersistenceController instance for Core Data
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                HomeView(
                    currentUsername: username,
                    profileImage: Binding<UIImage?>(
                        get: { profileImageData.flatMap { UIImage(data: $0) } },
                        set: { newImage in
                            profileImageData = newImage?.pngData()
                        }
                    )
                )
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
            } else {
                // Convert Binding<UIImage?> to Binding<Image?> for LoginView
                LoginView(
                    isLoggedIn: $isLoggedIn,
                    username: $username,
                    profileImage: Binding<Image?>(
                        get: {
                            if let data = profileImageData, let uiImage = UIImage(data: data) {
                                return Image(uiImage: uiImage)
                            }
                            return nil
                        },
                        set: { newImage in
                            profileImageData = newImage?.asUIImage()?.pngData()
                        }
                    )
                )
            }
        }
    }
}

// Extension to convert Image to UIImage
extension Image {
    func asUIImage() -> UIImage? {
        let controller = UIHostingController(rootView: self)
        let view = controller.view

        // Render the view to an image
        let targetSize = controller.view.intrinsicContentSize
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            view?.drawHierarchy(in: CGRect(origin: .zero, size: targetSize), afterScreenUpdates: true)
        }
    }
}
