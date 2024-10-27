import SwiftUI
import CoreData

@main
struct PawsomeApp: App {
    @State private var isLoggedIn: Bool = false
    @State private var username: String = ""
    @State private var profileImageData: Data? = nil // Use Data to store image
    @State private var showForm: Bool = false // For form visibility
    @State private var navigateToHome: Bool = false // For navigation

    // Shared PersistenceController instance for Core Data
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                TabView {
                    HomeView(
                        currentUsername: username,
                        profileImage: Binding<UIImage?>(
                            get: { profileImageData.flatMap { UIImage(data: $0) } },
                            set: { newImage in
                                profileImageData = newImage?.pngData()
                            }
                        )
                    )
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)

                    ScanView(
                        showForm: $showForm,
                        navigateToHome: $navigateToHome,
                        username: username
                    )
                    .tabItem {
                        Label("Post", systemImage: "plus.app")
                    }

                    ProfileView(
                        isLoggedIn: $isLoggedIn, // Pass isLoggedIn binding
                        currentUsername: $username, // Pass currentUsername binding
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
                // Ensure only necessary parameters are passed to LoginView
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
