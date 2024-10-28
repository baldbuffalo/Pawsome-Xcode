import SwiftUI
<<<<<<< HEAD
import SwiftData
=======
import CoreData
>>>>>>> 5eef0f8bd39986f9f45e071df446cc125709c1b6

@main
struct PawsomeApp: App {
    @State private var isLoggedIn: Bool = false
    @State private var username: String = ""
<<<<<<< HEAD
    @State private var profileImage: Image? = nil // Add @State for profileImage

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Item.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
=======
    @State private var profileImageData: Data? = nil
    @State private var showForm: Bool = false
    @State private var navigateToHome: Bool = false
    @State private var selectedImage: UIImage? = nil // This will hold the selected image

    // Shared PersistenceController instance for Core Data
    let persistenceController = PersistenceController.shared
>>>>>>> 5eef0f8bd39986f9f45e071df446cc125709c1b6

    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
<<<<<<< HEAD
                // Pass profileImage to HomeView
                HomeView(isLoggedIn: $isLoggedIn, currentUsername: $username, profileImage: $profileImage)
                    .modelContainer(sharedModelContainer)
            } else {
                // Pass all the required bindings, including profileImage
                LoginView(isLoggedIn: $isLoggedIn, username: $username, profileImage: $profileImage)
                    .modelContainer(sharedModelContainer)
=======
                TabView {
                    HomeView(
                       
                    )
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)

                    // Correct order of arguments in ScanView initializer
                    ScanView(
                        selectedImage: $selectedImage, // This should come first
                        showForm: $showForm, // Then showForm
                        username: username
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
>>>>>>> 5eef0f8bd39986f9f45e071df446cc125709c1b6
            }
        }
    }
}
<<<<<<< HEAD
=======

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
>>>>>>> 5eef0f8bd39986f9f45e071df446cc125709c1b6
