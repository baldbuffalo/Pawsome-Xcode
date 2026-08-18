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

    @State private var selectedItem: PhotosPickerItem?
    @State private var isPickingFile = false

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {

                avatarSection

                VStack(alignment: .leading, spacing: 6) {
                    Label("Username", systemImage: "person")
                        .font(.caption).foregroundColor(.secondary)

                    TextField("Username", text: $username)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { saveUsername() }

                    if !statusText.isEmpty {
                        Text(statusText).font(.footnote).foregroundColor(.green)
                    }
                }
                .padding(.horizontal)

                if let err = uploadError {
                    Text(err).font(.footnote).foregroundColor(.red).padding(.horizontal)
                }

                Spacer(minLength: 30)

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
        .onChange(of: selectedItem) { _, item in
            guard let item else { return }
            Task { await handlePhotoPickerItem(item) }
        }
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
                    .padding(6)
                    .background(Circle().fill(.background).shadow(radius: 2))  // ✅ no UIColor
                    .offset(x: 4, y: 4)
            }
            if isUploading {
                ProgressView("Updating photo…").font(.footnote)
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
                Image(systemName: "person.circle.fill").resizable().foregroundColor(.gray)
            }
        }
    }

    @ViewBuilder
    private var changePhotoButton: some View {
        #if os(iOS)
        PhotosPicker(selection: $selectedItem, matching: .images) {
            Image(systemName: "camera.circle.fill").font(.title2).foregroundStyle(.purple)
        }
        .disabled(isUploading)
        #else
        Button { isPickingFile = true } label: {
            Image(systemName: "camera.circle.fill").font(.title2).foregroundStyle(.purple)
        }
        .buttonStyle(.plain)
        .disabled(isUploading)
        #endif
    }

    // MARK: - iOS photo
    private func handlePhotoPickerItem(_ item: PhotosPickerItem) async {
        guard
            let data = try? await item.loadTransferable(type: Data.self),
            let uid  = Auth.auth().currentUser?.uid
        else { return }
        #if os(iOS)
        guard let image = UIImage(data: data) else { return }
        await uploadProfilePicture(image, uid: uid)
        #endif
    }

    // MARK: - macOS file
    #if os(macOS)
    private func handleFileURL(_ url: URL) async {
        guard
            let image = NSImage(contentsOf: url),
            let uid   = Auth.auth().currentUser?.uid
        else { return }
        await uploadProfilePicture(image, uid: uid)
    }
    #endif

    // MARK: - Upload → pawsome-assets/profilePictures/
    private func uploadProfilePicture(_ image: PlatformImage, uid: String) async {
        isUploading = true
        uploadError = nil
        do {
            let resized = image.resizedForUpload(maxDimension: 400)
            let newURL  = try await GitHubUploader.shared.uploadImage(
                resized, filename: "\(uid).jpg", folder: "profilePictures"
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

    // MARK: - Save username
    private func saveUsername() {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let uid = Auth.auth().currentUser?.uid,
              trimmed != appState.currentUsername
        else { return }

        Firestore.firestore().collection("users").document(uid)
            .updateData(["username": trimmed]) { error in
                guard error == nil else { return }
                Task { @MainActor in
                    appState.currentUsername = trimmed
                    statusText = "✓ Saved"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { statusText = "" }
                }
            }
    }
}
