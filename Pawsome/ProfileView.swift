import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import UniformTypeIdentifiers

struct ProfileView: View {
    @ObservedObject var appState: PawsomeApp.AppState

    @State private var username: String = ""
    @State private var isPickingImage = false
    @State private var isUploading = false
    @State private var statusText: String = ""

    var body: some View {
        VStack(spacing: 24) {

            // MARK: - Profile Image
            Button {
                isPickingImage = true
            } label: {
                profileImage
            }
            .disabled(isUploading)

            if isUploading {
                ProgressView("Updating profile picture…")
            }

            // MARK: - Username
            VStack(alignment: .leading, spacing: 6) {
                Text("Username")
                    .font(.caption)
                    .foregroundColor(.secondary)

                TextField("Username", text: $username, onCommit: saveUsername)
                    .textFieldStyle(.roundedBorder)

                if !statusText.isEmpty {
                    Text(statusText)
                        .font(.footnote)
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal)

            Spacer()

            // MARK: - Logout
            Button(role: .destructive) {
                appState.logout()
            } label: {
                Text("Logout")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
        }
        .padding()
        .fileImporter(
            isPresented: $isPickingImage,
            allowedContentTypes: [UTType.jpeg, UTType.png],
            allowsMultipleSelection: false,
            onCompletion: handleImagePick
        )
        .onAppear {
            username = appState.currentUsername
        }
    }

    // MARK: - Profile Image View
    private var profileImage: some View {
        Group {
            if let urlString = appState.profileImageURL,
               let url = URL(string: urlString),
               !urlString.isEmpty {

                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else if phase.error != nil {
                        Image(systemName: "person.crop.circle.badge.exclamationmark")
                    } else {
                        ProgressView()
                    }
                }

            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .foregroundColor(.gray)
            }
        }
        .frame(width: 120, height: 120)
        .clipShape(Circle())
        .shadow(radius: 5)
    }

    // MARK: - Handle Image Pick
    private func handleImagePick(_ result: Result<[URL], Error>) {
        guard
            case .success(let urls) = result,
            let fileURL = urls.first,
            let uid = Auth.auth().currentUser?.uid
        else { return }

        isUploading = true

        Task {
            do {
                let oldURL = appState.profileImageURL

                let newURL = try await GitHubUploader.shared.uploadProfileImage(
                    fileURL: fileURL,
                    userID: uid
                )

                try await saveProfilePicURL(newURL)

                if let oldURL, !oldURL.isEmpty {
                    try? await GitHubUploader.shared.deleteImage(from: oldURL)
                }

                await MainActor.run {
                    appState.profileImageURL = newURL
                    isUploading = false
                }

            } catch {
                await MainActor.run {
                    isUploading = false
                }
                print("❌ Image update failed:", error)
            }
        }
    }

    // MARK: - Save Username
    private func saveUsername() {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard
            !trimmed.isEmpty,
            let uid = Auth.auth().currentUser?.uid
        else { return }

        let ref = Firestore.firestore().collection("users").document(uid)
        ref.updateData(["username": trimmed]) { error in
            if error == nil {
                appState.currentUsername = trimmed
                statusText = "Saved"
            }
        }
    }

    // MARK: - Save Profile Pic URL
    private func saveProfilePicURL(_ url: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        try await Firestore.firestore()
            .collection("users")
            .document(uid)
            .updateData(["profilePic": url])
    }
}
