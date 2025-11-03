import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

// MARK: - ProfileViewModel
class ProfileViewModel: ObservableObject {
    @Published var selectedImage: PlatformImage?
    @Published var profileImage: PlatformImage?
    @Published var isImagePickerPresented = false
    @Binding var username: String
    @Published var isSaving: Bool = false
    @Published var isLoading: Bool = false
    @Published var isImageLoading: Bool = false

    init(username: Binding<String>) {
        self._username = username
    }

    // Load existing profile data from Firestore
    func loadProfileData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isLoading = true

        let userRef = Firestore.firestore().collection("users").document(uid)
        userRef.getDocument { snapshot, error in
            DispatchQueue.main.async {
                self.isLoading = false
                guard let data = snapshot?.data(), snapshot?.exists == true else { return }
                self.username = data["username"] as? String ?? self.username

                if let urlStr = data["profileImageURL"] as? String, let url = URL(string: urlStr) {
                    self.downloadImageFromURL(url: url)
                }
            }
        }
    }

    // MARK: - Download image from URL
    private func downloadImageFromURL(url: URL) {
        isImageLoading = true
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data {
                #if os(iOS)
                self.profileImage = UIImage(data: data)
                #elseif os(macOS)
                self.profileImage = NSImage(data: data)
                #endif
            }
            DispatchQueue.main.async { self.isImageLoading = false }
        }.resume()
    }

    // MARK: - Upload new profile image
    func uploadProfileImageToFirebase(image: PlatformImage) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let storageRef = Storage.storage().reference().child("profilePictures/\(uid).png")

        var imageData: Data?
        #if os(iOS)
        imageData = image.pngData()
        #elseif os(macOS)
        if let tiff = image.tiffRepresentation {
            imageData = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:])
        }
        #endif
        guard let data = imageData else { return }

        isImageLoading = true

        storageRef.putData(data, metadata: nil) { _, error in
            if let error = error {
                print("❌ Upload error: \(error.localizedDescription)")
                DispatchQueue.main.async { self.isImageLoading = false }
                return
            }

            storageRef.downloadURL { url, _ in
                if let url = url {
                    self.saveProfileImageURLToFirestore(url: url)
                } else {
                    DispatchQueue.main.async { self.isImageLoading = false }
                }
            }
        }
    }

    // MARK: - Save profile image URL to Firestore
    private func saveProfileImageURLToFirestore(url: URL) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let userRef = Firestore.firestore().collection("users").document(uid)

        userRef.setData(["profileImageURL": url.absoluteString], merge: true) { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Error saving profile URL: \(error.localizedDescription)")
                } else {
                    self.profileImage = self.selectedImage
                }
                self.isImageLoading = false
            }
        }
    }

    // MARK: - Save username to Firestore
    func saveUsernameToFirestore() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isSaving = true
        let userRef = Firestore.firestore().collection("users").document(uid)

        userRef.setData(["username": self.username], merge: true) { error in
            DispatchQueue.main.async {
                self.isSaving = false
                if let error = error {
                    print("❌ Error saving username: \(error.localizedDescription)")
                } else {
                    print("✅ Username updated")
                }
            }
        }
    }
}

// MARK: - ProfileView
struct ProfileView: View {
    @Binding var isLoggedIn: Bool
    @Binding var currentUsername: String
    @Binding var profileImage: PlatformImage?

    @StateObject private var viewModel: ProfileViewModel
    @FocusState private var usernameFocused: Bool

    init(isLoggedIn: Binding<Bool>, currentUsername: Binding<String>, profileImage: Binding<PlatformImage?>) {
        self._isLoggedIn = isLoggedIn
        self._currentUsername = currentUsername
        self._profileImage = profileImage
        _viewModel = StateObject(wrappedValue: ProfileViewModel(username: currentUsername))
    }

    var body: some View {
        VStack(spacing: 20) {
            if viewModel.isLoading || viewModel.isImageLoading {
                ProgressView("Loading Profile...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
            } else {
                profileImageView
                usernameField
                changePictureButton
                Spacer()
            }
        }
        .padding()
        .onAppear {
            viewModel.loadProfileData()
        }
        .sheet(isPresented: $viewModel.isImagePickerPresented) {
            ImagePickerView(selectedImage: $viewModel.selectedImage)
                .onDisappear {
                    if let selected = viewModel.selectedImage {
                        viewModel.uploadProfileImageToFirebase(image: selected)
                        self.profileImage = selected
                    }
                }
        }
    }

    private var profileImageView: some View {
        Group {
            if let img = viewModel.profileImage ?? profileImage {
                #if os(iOS)
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                #elseif os(macOS)
                Image(nsImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                #endif
            } else {
                Image(systemName: "person.crop.circle")
                    .resizable()
                    .frame(width: 120, height: 120)
                    .foregroundColor(.gray)
            }
        }
    }

    private var usernameField: some View {
        VStack {
            TextField("Username", text: $viewModel.username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.title2)
                .focused($usernameFocused)
                .onChange(of: usernameFocused) { newValue in
                    if !newValue { viewModel.saveUsernameToFirestore() }
                }

            Text(viewModel.isSaving ? "Saving..." : "Saved")
                .font(.caption)
                .foregroundColor(viewModel.isSaving ? .gray : .green)
        }
    }

    private var changePictureButton: some View {
        Button(action: { viewModel.isImagePickerPresented = true }) {
            Label("Change Profile Picture", systemImage: "camera")
        }
    }
}
