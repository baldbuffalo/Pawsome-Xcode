import SwiftUI

struct ProfileView: View {
    @ObservedObject var appState: PawsomeApp.AppState

    @State private var username: String = ""
    @State private var saveStatus: String = "" // "", "Saving...", "Saved"
    @State private var isTyping = false
    @State private var imagePickerPresented = false

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
            VStack(alignment: .leading, spacing: 5) {
                Text("Username")
                    .font(.caption)
                    .foregroundColor(.gray)

                TextField("Username", text: $username, onEditingChanged: { editing in
                    isTyping = editing
                    if editing {
                        saveStatus = "Saving..."
                    } else {
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

            // MARK: - Logout Button
            Button(action: {
                appState.logout()
            }) {
                Text("Logout")
                    .foregroundColor(.red)
                    .bold()
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
            }
            .padding(.horizontal)
        }
        .padding()
        .fileImporter(
            isPresented: $imagePickerPresented,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false,
            onCompletion: { result in
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
        )
    }

    // MARK: - Helpers
    private func saveUsername() {
        saveStatus = "Saving..."
        appState.saveUsername(username)
        // Only switch to "Saved" if user is not typing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if !isTyping {
                saveStatus = "Saved"
            }
        }
    }
}
