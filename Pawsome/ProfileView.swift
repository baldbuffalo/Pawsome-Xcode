import SwiftUI

struct ProfileView: View {
    @ObservedObject var appState: PawsomeApp.AppState

    @State private var username: String = ""
    @State private var saveStatus: String = ""
    @State private var isTyping = false
    @State private var imagePickerPresented = false

    #if os(macOS)
    @State private var isHoveringLogout = false
    #endif

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

                TextField("Username", text: $username, onEditingChanged: { editing in
                    isTyping = editing
                    saveStatus = editing ? "Saving..." : ""
                }, onCommit: {
                    saveUsername()
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())

                if !saveStatus.isEmpty {
                    Text(saveStatus)
                        .font(.footnote)
                        .foregroundColor(saveStatus == "Saved" ? .green : .orange)
                }
            }
            .padding(.horizontal)

            Spacer()

            // MARK: - Logout Button
            logoutButton()
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
           let url = URL(string: urlString),
           let data = try? Data(contentsOf: url),
           let image = PlatformImage(data: data) {

            Image(platformImage: image)
                .resizable()
                .scaledToFill()
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

    // MARK: - Logout Button
    private func logoutButton() -> some View {
        Button {
            appState.logout()   // 🔥 flips isLoggedIn = false and resets defaults
        } label: {
            Text("Logout")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(Color.red)
                .cornerRadius(10)
        }
        .padding(.horizontal)
        #if os(macOS)
        .buttonStyle(BorderlessButtonStyle())
        .onHover { isHoveringLogout = $0 }
        #endif
    }

    // MARK: - Image Picker
    private func handleImagePick(result: Result<[URL], Error>) {
        if case .success(let urls) = result,
           let url = urls.first {
            appState.saveProfileImageURL(url.absoluteString)
        }
    }

    // MARK: - Username Save
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

// MARK: - PlatformImage → SwiftUI Image
extension Image {
    #if os(iOS)
    init(platformImage: UIImage) { self.init(uiImage: platformImage) }
    #elseif os(macOS)
    init(platformImage: NSImage) { self.init(nsImage: platformImage) }
    #endif
}
