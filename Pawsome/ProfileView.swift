import SwiftUI

struct ProfileView: View {
    @ObservedObject var appState: PawsomeApp.AppState

    @State private var username: String = ""
    @State private var saveStatus: String = ""
    @State private var isTyping = false
    @State private var imagePickerPresented = false
    @State private var showLogoutConfirm = false

    var body: some View {
        VStack(spacing: 30) {

            // MARK: - Profile Image
            Button {
                imagePickerPresented = true
            } label: {
                if let urlString = appState.profileImageURL,
                   let url = URL(string: urlString),
                   let data = try? Data(contentsOf: url) {

                    #if os(iOS)
                    if let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    }
                    #elseif os(macOS)
                    if let nsImage = NSImage(data: data) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    }
                    #endif

                } else {
                    Image(systemName: "person.circle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .foregroundColor(.gray)
                }
            }

            // MARK: - Username Field
            VStack(alignment: .leading, spacing: 6) {
                Text("Username")
                    .font(.caption)
                    .foregroundColor(.gray)

                TextField("Username", text: $username, onEditingChanged: { editing in
                    isTyping = editing
                    saveStatus = editing ? "Saving..." : ""
                    if !editing {
                        saveUsername()
                    }
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onAppear {
                    username = appState.currentUsername
                }

                if !saveStatus.isEmpty {
                    Text(saveStatus)
                        .font(.footnote)
                        .foregroundColor(saveStatus == "Saved" ? .green : .orange)
                }
            }
            .padding(.horizontal)

            Spacer()

            // MARK: - Logout Button (FULL AREA CLICKABLE)
            Button(role: .destructive) {
                showLogoutConfirm = true
            } label: {
                HStack {
                    Spacer()
                    Text("Logout")
                        .font(.headline)
                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.red.opacity(0.12))
                )
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            .padding(.horizontal)
            .confirmationDialog(
                "Are you sure you want to log out?",
                isPresented: $showLogoutConfirm,
                titleVisibility: .visible
            ) {
                Button("Log out", role: .destructive) {
                    #if os(iOS)
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    #endif
                    appState.logout()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
        .padding()
        .fileImporter(
            isPresented: $imagePickerPresented,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let selectedURL = urls.first {
                    appState.saveProfileImageURL(selectedURL.absoluteString)
                }
            case .failure(let error):
                print("Image pick failed:", error)
            }
        }
    }

    // MARK: - Helpers
    private func saveUsername() {
        saveStatus = "Saving..."
        appState.saveUsername(username)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if !isTyping {
                saveStatus = "Saved"
            }
        }
    }
}
