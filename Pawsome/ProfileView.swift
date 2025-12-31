import SwiftUI

struct ProfileView: View {
    @ObservedObject var appState: PawsomeApp.AppState
    @Environment(\.presentationMode) var presentationMode // iOS modal dismissal

    @State private var username: String = ""
    @State private var saveStatus: String = "" // "", "Saving...", "Saved"
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

            // MARK: - Username Field
            VStack(alignment: .leading, spacing: 5) {
                Text("Username")
                    .font(.caption)
                    .foregroundColor(.gray)

                TextField("Username", text: $username, onEditingChanged: { editing in
                    #if os(iOS)
                    isTyping = editing
                    if editing { saveStatus = "Saving..." }
                    else { saveUsername() }
                    #endif
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

    // MARK: - Profile Image
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
            Image(systemName: "person.circle")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundColor(.gray)
        }
    }

    // MARK: - Logout Button
    @ViewBuilder
    private func logoutButton() -> some View {
        Button {
            appState.logout()                   // Update state
            #if os(iOS)
            presentationMode.wrappedValue.dismiss() // Close sheet/modal
            #endif
        } label: {
            Text("Logout")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(buttonBackgroundColor())
                .cornerRadius(8)
        }
        .padding(.horizontal)
        #if os(macOS)
        .buttonStyle(BorderlessButtonStyle())
        .onHover { hovering in
            isHoveringLogout = hovering
        }
        #endif
    }

    private func buttonBackgroundColor() -> Color {
        #if os(macOS)
        return isHoveringLogout ? Color.red.opacity(0.8) : Color.red
        #else
        return Color.red
        #endif
    }

    // MARK: - Image Picker Handler
    private func handleImagePick(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let selectedURL = urls.first {
                let urlString = selectedURL.absoluteString
                appState.saveProfileImageURL(urlString)
            }
        case .failure(let error):
            print("Image pick failed:", error)
        }
    }

    // MARK: - Username Saving
    private func saveUsername() {
        let trimmed = username.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        saveStatus = "Saving..."

        // Only update the "username" field in Firebase, keeping other fields intact
        appState.saveUsername(trimmed) {
            #if os(iOS)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                if !isTyping { saveStatus = "Saved" }
            }
            #elseif os(macOS)
            saveStatus = "Saved"
            #endif
        }
    }
}

// MARK: - Image Extension for PlatformImage
extension Image {
    #if os(iOS)
    init(platformImage: UIImage) { self.init(uiImage: platformImage) }
    #elseif os(macOS)
    init(platformImage: NSImage) { self.init(nsImage: platformImage) }
    #endif
}
