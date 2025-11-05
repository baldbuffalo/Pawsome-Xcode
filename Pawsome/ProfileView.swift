import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

class ProfileViewModel: ObservableObject {
    @Published var profileImageURL: String?
    @Published var selectedImage: PlatformImage?
    @Published var isImageLoading = false
    @Published var isSaving = false
    @Published var isImagePickerPresented = false
    @Binding var username: String
    @Published var isLoading = false

    init(username: Binding<String>) {
        self._username = username
    }

    func loadProfile() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        let docRef = Firestore.firestore().collection("users").document(uid)
        docRef.getDocument { snapshot, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let data = snapshot?.data() {
                    self.username = data["username"] as? String ?? self.username
                    self.profileImageURL = data["profileImage"] as? String
                }
            }
        }
    }

    func saveUsername() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isSaving = true
        Firestore.firestore().collection("users").document(uid).setData(
            ["username": username], merge: true
        ) { _ in
            DispatchQueue.main.async { self.isSaving = false }
        }
    }

    func uploadProfileImage(image: PlatformImage) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let ref = Storage.storage().reference().child("profilePictures/\(uid).png")
        var data: Data?

        #if os(iOS)
        data = image.pngData()
        #elseif os(macOS)
        if let tiff = image.tiffRepresentation {
            data = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:])
        }
        #endif

        guard let uploadData = data else { return }
        isImageLoading = true

        do {
            _ = try await ref.putDataAsync(uploadData)
            let url = try await ref.downloadURL()
            profileImageURL = url.absoluteString
            Firestore.firestore().collection("users").document(uid)
                .setData(["profileImage": url.absoluteString], merge: true)
        } catch {
            print("❌ Image upload failed: \(error.localizedDescription)")
        }

        DispatchQueue.main.async { self.isImageLoading = false }
    }
}

struct ProfileView: View {
    @Binding var isLoggedIn: Bool
    @Binding var currentUsername: String
    @Binding var profileImageURL: String?

    @StateObject private var vm: ProfileViewModel
    @FocusState private var usernameFocused: Bool

    init(isLoggedIn: Binding<Bool>, currentUsername: Binding<String>, profileImageURL: Binding<String?>) {
        self._isLoggedIn = isLoggedIn
        self._currentUsername = currentUsername
        self._profileImageURL = profileImageURL
        _vm = StateObject(wrappedValue: ProfileViewModel(username: currentUsername))
    }

    var body: some View {
        VStack(spacing: 16) {
            if vm.isLoading {
                ProgressView("Loading Profile...").padding()
            } else {
                if let urlString = vm.profileImageURL ?? profileImageURL,
                   let url = URL(string: urlString) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFit()
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 120, height: 120)
                        .foregroundColor(.gray)
                }

                TextField("Username", text: $vm.username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($usernameFocused)
                    .onChange(of: usernameFocused) { focused in
                        if !focused { vm.saveUsername() }
                    }

                Text(vm.isSaving ? "Saving..." : "Saved")
                    .foregroundColor(vm.isSaving ? .gray : .green)
                    .font(.caption)

                Button("Change Profile Picture") {
                    vm.isImagePickerPresented = true
                }

                Spacer()
            }
        }
        .padding()
        .onAppear { vm.loadProfile() }
        .sheet(isPresented: $vm.isImagePickerPresented) {
            ImagePickerView(selectedImage: $vm.selectedImage)
                .onDisappear {
                    if let image = vm.selectedImage {
                        Task { await vm.uploadProfileImage(image: image) }
                    }
                }
        }
    }
}
