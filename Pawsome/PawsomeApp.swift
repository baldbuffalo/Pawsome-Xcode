import SwiftUI
import CoreData

@main
struct PawsomeApp: App {
    @State private var isLoggedIn: Bool = false
    @State private var username: String = ""
    @State private var profileImageData: Data? = nil
    @State private var selectedImage: UIImage? = nil // This will hold the selected image

    // Shared PersistenceController instance for Core Data
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                TabView {
                    HomeView(
                        isLoggedIn: $isLoggedIn,
                        currentUsername: $username,
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
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)

                    // Pass the Core Data context and handle post creation directly
                    ScanView(
                        capturedImage: $selectedImage, // Pass the selected image binding
                        username: username,
                        onPostCreated: { catPost in
                            // Handle the created post using Core Data here
                            savePostToCoreData(capturedImage: selectedImage, username: username)
                        }
                    )
                    .tabItem {
                        Label("Post", systemImage: "plus.app")
                    }

                    ProfileView(
                        isLoggedIn: $isLoggedIn,
                        currentUsername: $username,
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
                    .tabItem {
                        Label("Profile", systemImage: "person.circle")
                    }
                }
            } else {
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

    // Function to save post data to Core Data
    private func savePostToCoreData(capturedImage: UIImage?, username: String) {
        let context = persistenceController.container.viewContext
        let newPost = CatPost(context: context) // Use the CatPost entity
        newPost.username = username
        newPost.timestamp = Date()

        // Convert UIImage to Data for Core Data
        if let image = capturedImage, let imageData = image.jpegData(compressionQuality: 1.0) {
            newPost.imageData = imageData
        }

        do {
            try context.save()
        } catch {
            print("Failed to save post: \(error.localizedDescription)")
        }
    }
}

// Extension to convert Image to UIImage
extension Image {
    func asUIImage() -> UIImage? {
        let controller = UIHostingController(rootView: self)
        let view = controller.view
        
        // Render the view to an image
        let targetSize = view?.intrinsicContentSize ?? .zero
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            view?.drawHierarchy(in: CGRect(origin: .zero, size: targetSize), afterScreenUpdates: true)
        }
    }
}
