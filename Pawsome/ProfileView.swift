import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

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
        _vm = StateObject(wrappedValue: ProfileViewModel(username: currentUsername.wrappedValue))
    }

    var body: some View {
        VStack(spacing: 16) {

            // Profile Image
            Group {
                if let selected = vm.selectedImage {
                    #if os(iOS)
                    Image(uiImage: selected)
                        .resizable()
                        .scaledToFill()
                    #elseif os(macOS)
                    Image(nsImage: selected)
                        .resizable()
                        .scaledToFill()
                    #endif
                } else if let urlString = vm.profileImageURL ?? profileImageURL,
                          let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty: ProgressView()
                        case .success(let img): img.resizable().scaledToFill()
                        default: Image(systemName: "person.crop.circle.fill")
                            .resizable().scaledToFill()
                        }
                    }
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .foregroundColor(.gray)
                }
            }
            .frame(width: 120, height: 120)
            .clipShape(Circle())

            // Username Field
            TextField("Username", text: $vm.username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .focused($usernameFocused)

            // Saving / Saved Status
            Text(vm.saveStatusText)
                .foregroundColor(vm.saveStatusText == "Saved" ? .green : .gray)
                .font(.caption)

            // Change Picture
            Button("Change Profile Picture") {
                vm.isImagePickerPresented = true
            }

            // Logout
            Button(role: .destructive) {
                vm.logout()
                isLoggedIn = false
                currentUsername = ""
                profileImageURL = nil
            } label: {
                Text("Log Out").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)

            Spacer()
        }
        .padding()
        .sheet(isPresented: $vm.isImagePickerPresented) {
            ImagePickerView(selectedImage: $vm.selectedImage)
        }
        .onAppear {
            vm.loadProfile()
        }
        .onChange(of: vm.username) { _, newValue in
            currentUsername = newValue
        }
        .onChange(of: vm.profileImageURL) { _, newValue in
            profileImageURL = newValue
        }
    }
}

@MainActor
class ProfileViewModel: ObservableObject {

    @Published var username: String {
        didSet { handleUsernameChanged() }
    }

    @Published var profileImageURL: String?
    @Published var selectedImage: PlatformImage? {
        didSet { if selectedImage != nil { Task { await uploadProfileImage() } } }
    }

    @Published var isImagePickerPresented = false
    @Published var isSaving = false
    @Published var isTyping = false
    @Published var saveStatusText = "Saved"

    private var typingTimer: Timer?
    private var userID: String?
    private let db = Firestore.firestore()

    init(username: String) {
        self.username = username
        self.userID = Auth.auth().currentUser?.uid
    }

    func loadProfile() {
        guard let uid = userID else { return }
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let data = snapshot?.data() {
                self.username = data["username"] as? String ?? self.username
                self.profileImageURL = data["profileImageURL"] as? String
            }
        }
    }

    // MARK: - Username Handling
    private func handleUsernameChanged() {
        guard userID != nil else { return }

        isTyping = true
        isSaving = true
        saveStatusText = "Saving…"

        typingTimer?.invalidate()

        typingTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: false) { [weak self] _ in
            Task { await self?.userStoppedTyping() }
        }

        saveUsernameInstant()
    }

    private func userStoppedTyping() async {
        isTyping = false

        if isSaving {
            saveStatusText = "Saving…"
        } else {
            saveStatusText = "Saved"
        }
    }

    private func saveUsernameInstant() {
        guard let uid = userID else { return }

        db.collection("users").document(uid)
            .setData(["username": username], merge: true) { error in

                self.isSaving = false

                if self.isTyping {
                    self.saveStatusText = "Saving…"
                } else {
                    self.saveStatusText = "Saved"
                }
            }
    }

    // MARK: - Image Upload
    func uploadProfileImage() async {
        guard let uid = userID else { return }
        guard let img = selectedImage else { return }

        isSaving = true
        saveStatusText = "Saving…"

        let ref = Storage.storage().reference()
            .child("profileImages/\(uid).jpg")

        #if os(iOS)
        guard let data = img.jpegData(compressionQuality: 0.8) else { return }
        #elseif os(macOS)
        guard let tiff = img.tiffRepresentation,
              let data = NSBitmapImageRep(data: tiff)?
                .representation(using: .jpeg, properties: [.compressionFactor: 0.8]) else { return }
        #endif

        do {
            _ = try await ref.putDataAsync(data)
            let url = try await ref.downloadURL()
            let urlString = url.absoluteString

            try await db.collection("users").document(uid)
                .setData(["profileImageURL": urlString], merge: true)

            await MainActor.run {
                self.profileImageURL = urlString
                self.isSaving = false

                if self.isTyping {
                    self.saveStatusText = "Saving…"
                } else {
                    self.saveStatusText = "Saved"
                }
            }
        } catch {
            print("Image upload failed: \(error)")
        }
    }

    // MARK: - Logout
    func logout() {
        try? Auth.auth().signOut()
        UserDefaults.standard.removeObject(forKey: "username")
        UserDefaults.standard.removeObject(forKey: "profileImageURL")
    }
}
