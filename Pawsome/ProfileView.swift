import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import PhotosUI

struct ProfileView: View {
    @ObservedObject var appState: PawsomeApp.AppState

    @State private var username      = ""
    @State private var statusText    = ""
    @State private var isUploading   = false
    @State private var uploadError: String?

    // iOS — PhotosPicker
    @State private var selectedItem: PhotosPickerItem?

    // macOS — fileImporter
    @State private var isPickingFile = false

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {

                // ── Avatar ──────────────────────────────────────────────
                avatarSection

                // ── Username ─────────────────────────────────────────────
                VStack(alignment: .leading, spacing: 6) {
                    Label("Username", systemImage: "person")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextField("Username", text: $username)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { saveUsername() }

                    if !statusText.isEmpty {
                        Text(statusText)
                            .font(.footnote)
                            .foregroundColor(.green)
                    }
                }
                .padding(.horizontal)

                if let err = uploadError {
                    Text(err)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }

                Spacer(minLength: 30)

                // ── Logout ───────────────────────────────────────────────
                Button(role: .destructive) {
                    Task { @MainActor in appState.logout() }
                } label: {
                    Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                        .frame(maxWidth: .infinity, minHeight: 46)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red.opacity(0.85))
                .padding(.horizontal)
            }
            .padding(.vertical, 24)
        }
        .onAppear { username = appState.currentUsername }

        // iOS: react to PhotosPicker selection
        .onChange(of: selectedItem) { _, item in
            guard let item else { return }
            Task { await handlePhotoPickerItem(item) }
        }

        // macOS: file importer
        #if os(macOS)
        .fileImporter(
            isPresented: $isPickingFile,
            allowedContentTypes: [.jpeg, .png, .heic],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                Task { await handleFileURL(url) }
            }
        }
        #endif
    }

    // MARK: - Avatar
    private var avatarSection: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                profileImage
                    .frame(width: 110, height: 110)
                    .clipShape(Circle())
                    .shadow(radius: 6)

                changePhotoButton
                    .background(Circle().fill(Color(uiColorCompat: .systemBackground)).padding(-2))
            }

            if isUploading {
                ProgressView("Updating photo…")
                    .font(.footnote)
            }
        }
    }

    private var profileImage: some View {
        Group {
            if let urlString = appState.profileImageURL,
               let url = URL(string: urlString), !urlString.isEmpty {
                AsyncImage(url: url) { phase in
                    if let img = phase.image {
                        img.resizable().scaledToFill()
                    } else if phase.error != nil {
                        Image(systemName: "person.crop.circle.badge.exclamationmark")
                            .resizable().scaledToFit().foregroundColor(.gray)
                    } else {
                        ProgressView()
                    }
                }
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable().foregroundColor(.gray)
            }
        }
    }

    @ViewBuilder
    private var changePhotoButton: some View {
        #if os(iOS)
        PhotosPicker(selection: $selectedItem, matching: .images) {
            Image(systemName: "camera.circle.fill")
                .font(.title2)
                .foregroundStyle(.purple)
        }
        .disabled(isUploading)
        #else
        Button { isPickingFile = true } label: {
            Image(systemName: "camera.circle.fill")
                .font(.title2)
                .foregroundStyle(.purple)
        }
        .buttonStyle(.plain)
        .disabled(isUploading)
        #endif
    }

    // MARK: - iOS Photo Handling
    private func handlePhotoPickerItem(_ item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let uid  = Auth.auth().currentUser?.uid else { return }

        #if os(iOS)
        guard let image = UIImage(data: data) else { return }
        await uploadProfilePicture(image, uid: uid)
        #endif
    }

    // MARK: - macOS File Handling
    #if os(macOS)
    private func handleFileURL(_ url: URL) async {
        guard let image = NSImage(contentsOf: url),
              let uid   = Auth.auth().currentUser?.uid else { return }
        await uploadProfilePicture(image, uid: uid)
    }
    #endif

    // MARK: - Shared Upload
    private func uploadProfilePicture(_ image: PlatformImage, uid: String) async {
        isUploading = true
        uploadError = nil

        do {
            let resized = image.resizedForUpload(maxDimension: 400)
            let newURL  = try await GitHubUploader.shared.uploadImage(
                resized,
                filename: "\(uid).jpg",
                folder:   "profilePictures"
            )
            try await Firestore.firestore()
                .collection("users").document(uid)
                .updateData(["profilePic": newURL])

            await MainActor.run {
                appState.profileImageURL = newURL
                isUploading = false
            }
        } catch {
            await MainActor.run {
                uploadError = error.localizedDescription
                isUploading = false
            }
        }
    }

    // MARK: - Save Username
    private func saveUsername() {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard
            !trimmed.isEmpty,
            let uid = Auth.auth().currentUser?.uid,
            trimmed != appState.currentUsername
        else { return }

        Firestore.firestore()
            .collection("users").document(uid)
            .updateData(["username": trimmed]) { error in
                if error == nil {
                    Task { @MainActor in
                        appState.currentUsername = trimmed
                        statusText = "✓ Saved"
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { statusText = "" }
                    }
                }
            }
    }
}

// MARK: - Cross-platform color helper
extension Color {
    init(uiColorCompat: Any) {
        #if os(iOS)
        if let c = uiColorCompat as? UIColor { self = Color(c); return }
        #endif
        self = .white
    }
}
