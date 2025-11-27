import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class ProfileViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var selectedImage: PlatformImage? = nil
    @Published var isImagePickerPresented = false

    init() {
        username = UserDefaults.standard.string(forKey: "username") ?? ""
    }

    func saveUsername() {
        UserDefaults.standard.set(username, forKey: "username")

        if let uid = Auth.auth().currentUser?.uid {
            Firestore.firestore().collection("users").document(uid)
                .setData(["username": username], merge: true)
        }
    }
}

struct ProfileView: View {
    @StateObject private var vm = ProfileViewModel()

    var body: some View {
        VStack(spacing: 20) {
            // MARK: - Profile Image
            Group {
                if let img = vm.selectedImage {
                    #if os(iOS)
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                    #elseif os(macOS)
                    Image(nsImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                    #endif
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 120, height: 120)
                        .overlay(Text("Tap").foregroundColor(.gray))
                }
            }
            .onTapGesture { vm.isImagePickerPresented = true }

            // MARK: - Username
            TextField("Enter username", text: $vm.username)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            // MARK: - Save Button
            Button("Save Changes") {
                vm.saveUsername()
            }
            .padding()
        }
        .padding()

        // MARK: - new macOS/iOS 17 onChange
        .onChange(of: vm.username) {
            vm.saveUsername()
        }

        .sheet(isPresented: $vm.isImagePickerPresented) {
            PlatformImagePicker { img in
                vm.selectedImage = img
            }
        }
    }
}

// MARK: - Image Picker Wrapper
struct PlatformImagePicker: View {
    var onSelect: (PlatformImage) -> Void

    var body: some View {
        #if os(iOS)
        ImagePickerView(onSelect: onSelect)
        #elseif os(macOS)
        MacImagePicker(onSelect: onSelect)
        #endif
    }
}

#if os(iOS)
struct ImagePickerView: UIViewControllerRepresentable {
    var onSelect: (PlatformImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ vc: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onSelect: onSelect)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var onSelect: (UIImage) -> Void

        init(onSelect: @escaping (UIImage) -> Void) {
            self.onSelect = onSelect
        }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let img = info[.originalImage] as? UIImage {
                onSelect(img)
            }
            picker.dismiss(animated: true)
        }
    }
}
#endif

#if os(macOS)
struct MacImagePicker: NSViewControllerRepresentable {
    var onSelect: (PlatformImage) -> Void

    func makeNSViewController(context: Context) -> NSViewController {
        let vc = NSViewController()
        DispatchQueue.main.async {
            let panel = NSOpenPanel()
            panel.allowedContentTypes = [.image]
            panel.begin { response in
                if response == .OK, let url = panel.url, let img = NSImage(contentsOf: url) {
                    onSelect(img)
                }
            }
        }
        return vc
    }

    func updateNSViewController(_ controller: NSViewController, context: Context) {}
}
#endif
