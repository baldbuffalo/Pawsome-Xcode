import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var username: String
    @Published var profileImageURL: String?
    @Published var selectedImage: PlatformImage?
    @Published var isImageLoading = false
    @Published var isSaving = false
    @Published var isImagePickerPresented = false
    @Published var isLoading = false

    init(username: String) {
        self.username = username
    }

    func loadProfile() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        let docRef = Firestore.firestore().collection("users").document(uid)

        docRef.getDocument { [weak self] snapshot, _ in
            guard let self = self else { return }
            Task { @MainActor in
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
        Firestore.firestore().collection("users").document(uid)
            .setData(["username": username], merge: true) { [weak self] _ in
                guard let self = self else { return }
                Task { @MainActor in
                    self.isSaving = false
                }
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
            try await Firestore.firestore().collection("users").document(uid)
                .setData(["profileImage": url.absoluteString], merge: true)
        } catch {
            print("❌ Image upload failed: \(error.localizedDescription)")
        }

        isImageLoading = false
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
        _vm = StateObject(wrappedValue: ProfileViewModel(username: currentUsername.wrappedValue))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                if vm.isLoading {
                    ProgressView("Loading Profile...").padding()
                }

                // Profile image
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

                // Username field
                TextField("Username", text: $vm.username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($usernameFocused)
                    .onChange(of: usernameFocused) { _, newValue in
                        if !newValue {
                            vm.saveUsername()
                            currentUsername = vm.username
                        }
                    }

                Text(vm.isSaving ? "Saving..." : "Saved")
                    .foregroundColor(vm.isSaving ? .gray : .green)
                    .font(.caption)

                // ✅ Buttons always visible
                Button("Change Profile Picture") {
                    vm.isImagePickerPresented = true
                }

                Button(role: .destructive) {
                    do {
                        try Auth.auth().signOut()
                        currentUsername = ""
                        profileImageURL = nil
                        UserDefaults.standard.removeObject(forKey: "username")
                        UserDefaults.standard.set(false, forKey: "isLoggedIn")
                        isLoggedIn = false
                    } catch {
                        print("❌ Logout failed: \(error)")
                    }
                } label: {
                    Text("Log Out")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)

                Spacer()
            }
            .padding()
        }
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
