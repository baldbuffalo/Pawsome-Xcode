import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ProfileView: View {
    @Binding var isLoggedIn: Bool
    @Binding var currentUsername: String
    @Binding var profileImageURL: String?

    @StateObject private var vm: ProfileViewModel
    @FocusState private var usernameFocused: Bool

    init(
        isLoggedIn: Binding<Bool>,
        currentUsername: Binding<String>,
        profileImageURL: Binding<String?>
    ) {
        self._isLoggedIn = isLoggedIn
        self._currentUsername = currentUsername
        self._profileImageURL = profileImageURL

        let uid = Auth.auth().currentUser?.uid ?? "unknown"
        _vm = StateObject(
            wrappedValue: ProfileViewModel(
                username: currentUsername.wrappedValue,
                uid: uid
            )
        )
    }

    var body: some View {
        VStack(spacing: 18) {

            // MARK: - Profile Image
            profileImageSection

            // MARK: - Username Field
            TextField("Username", text: $vm.username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .focused($usernameFocused)
                .onChange(of: vm.username) { oldValue, newValue in
                    vm.isTyping = true
                    vm.userTyped()
                }
                .onSubmit {
                    vm.isTyping = false
                    vm.userTyped()
                }

            // MARK: - Saving Indicator
            if vm.isTyping || vm.isSaving {
                Text("Saving...")
                    .foregroundColor(.gray)
                    .font(.caption)
            } else if vm.showSaved {
                Text("Saved")
                    .foregroundColor(.green)
                    .font(.caption)
            }

            // MARK: - Change picture
            Button("Change Profile Picture") {
                vm.isImagePickerPresented = true
            }

            // MARK: - Logout
            Button(role: .destructive) {
                logout()
            } label: {
                Text("Log Out")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)

            Spacer()
        }
        .padding()
        .onAppear {
            vm.loadProfile()
        }
        .sheet(isPresented: $vm.isImagePickerPresented) {
            ImagePickerView(selectedImage: $vm.selectedImage)
                .onDisappear {
                    if let img = vm.selectedImage {
                        Task {
                            await vm.uploadProfileImage(image: img)
                        }
                    }
                }
        }
    }
}

// MARK: - UI Helpers

private extension ProfileView {

    @ViewBuilder
    var profileImageSection: some View {
        if let selected = vm.selectedImage {
            platformImageView(selected)
        } else if let urlString = vm.profileImageURL,
                  let url = URL(string: urlString) {

            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                case .success(let img):
                    img.resizable().scaledToFit()
                default:
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFit()
                }
            }
            .frame(width: 120, height: 120)
            .clipShape(Circle())

        } else {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .frame(width: 120, height: 120)
                .foregroundColor(.gray)
        }
    }

    // Cross-platform
    @ViewBuilder
    func platformImageView(_ img: PlatformImage) -> some View {
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
    }

    func logout() {
        try? Auth.auth().signOut()
        currentUsername = ""
        profileImageURL = nil
        UserDefaults.standard.removeObject(forKey: "username")
        UserDefaults.standard.removeObject(forKey: "profileImageURL")
        UserDefaults.standard.set(false, forKey: "isLoggedIn")
        isLoggedIn = false
    }
}

/////////////////////////////////////////////////////////////
// MARK: - PROFILE VIEW MODEL (COMBINED)
/////////////////////////////////////////////////////////////

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var username: String
    @Published var profileImageURL: String?
    @Published var selectedImage: PlatformImage?

    @Published var isImagePickerPresented = false
    @Published var isSaving = false
    @Published var showSaved = false
    @Published var isTyping = false

    let uid: String
    private let db = Firestore.firestore()
    private var debounceTask: Task<Void, Never>?

    init(username: String, uid: String) {
        self.username = username
        self.uid = uid
    }

    // MARK: - Load From UserDefaults
    func loadProfile() {
        username = UserDefaults.standard.string(forKey: "username") ?? username
        profileImageURL = UserDefaults.standard.string(forKey: "profileImageURL")
    }

    // MARK: - Debounced Username Saving
    func userTyped() {
        debounceTask?.cancel()

        debounceTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s

            isTyping = false
            await saveUsername()
        }
    }

    // MARK: - Save Username to Firestore
    func saveUsername() async {
        guard !username.isEmpty else { return }

        isSaving = true
        showSaved = false

        do {
            try await db.collection("users").document(uid).setData([
                "username": username
            ], merge: true)

            UserDefaults.standard.set(username, forKey: "username")

            isSaving = false
            showSaved = true

        } catch {
            print("❌ Firestore save failed:", error)
            isSaving = false
        }
    }

    // MARK: - Upload Profile Image
    func uploadProfileImage(image: PlatformImage) async {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("profile.png")

        #if os(iOS)
        if let data = image.pngData() {
            try? data.write(to: url)
        }
        #elseif os(macOS)
        if let data = NSBitmapImageRep(data: image.tiffRepresentation!)?
            .representation(using: .png, properties: [:]) {
            try? data.write(to: url)
        }
        #endif

        profileImageURL = url.absoluteString
        UserDefaults.standard.set(profileImageURL, forKey: "profileImageURL")

        // Save URL also in Firestore
        try? await db.collection("users").document(uid).setData([
            "profileImageURL": profileImageURL ?? ""
        ], merge: true)
    }
}

