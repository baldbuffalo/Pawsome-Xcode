import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ProfileView: View {
    @ObservedObject var appState: PawsomeApp.AppState

    @State private var username: String = ""
    @State private var saveStatus: String = ""
    @State private var isTyping = false
    @State private var imagePickerPresented = false

    var body: some View {
        VStack(spacing: 30) {

            // MARK: - Profile Image
            Button {
                imagePickerPresented = true
            } label: {
                profileImageView()
            }

            // MARK: - Username
            VStack(alignment: .leading, spacing: 6) {
                Text("Username")
                    .font(.caption)
                    .foregroundColor(.gray)

                TextField(
                    "Username",
                    text: $username,
                    onEditingChanged: { editing in
                        isTyping = editing
                        saveStatus = editing ? "Saving..." : ""
                    },
                    onCommit: saveUsername
                )
                .textFieldStyle(.roundedBorder)

                if !saveStatus.isEmpty {
                    Text(saveStatus)
                        .font(.footnote)
                        .foregroundColor(saveStatus == "Saved" ? .green : .orange)
                }
            }
            .padding(.horizontal)

            Spacer()

            // MARK: - Logout
            Button {
                appState.logout()
            } label: {
                Text("Logout")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(Color.red)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .padding()
        .fileImporter(
            isPresented: $imagePickerPresented,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false,
            onCompletion: handleImagePick
        )
        .onAppear {
            username = appState.currentUsername
        }
    }

    // MARK: - Profile Image View
    @ViewBuilder
    private func profileImageView() -> some View {
        if let urlString = appState.profileImageURL,
           let url = URL(string: urlString) {

            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .scaledToFill()
                } else if phase.error != nil {
                    Image(systemName: "person.crop.circle.badge.exclamationmark")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.gray)
                } else {
                    ProgressView()
                }
            }
            .frame(width: 120, height: 120)
            .clipShape(Circle())
            .shadow(radius: 5)

        } else {
            Image(systemName: "person.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundColor(.gray)
        }
    }

    // MARK: - Image Picker
    private func handleImagePick(result: Result<[URL], Error>) {
        guard
            case .success(let urls) = result,
            let url = urls.first
        else { return }

        // You are storing URLs ONLY (GitHub, CDN, etc.)
        appState.saveProfileImageURL(url.absoluteString)
    }

    // MARK: - Save Username
    private func saveUsername() {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        saveStatus = "Saving..."
        appState.saveUsername(trimmed) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                if !isTyping {
                    saveStatus = "Saved"
                }
            }
        }
    }
}
