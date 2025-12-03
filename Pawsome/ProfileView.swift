import SwiftUI
import UniformTypeIdentifiers

struct ProfileView: View {
    @ObservedObject var appState: PawsomeApp.AppState
    @State private var username: String = ""

    var body: some View {
        VStack(spacing: 20) {
            // Profile Image
            if let urlString = appState.profileImageURL,
               let url = URL(string: urlString),
               let image = NSImage(contentsOf: url) {
                Image(nsImage: image)
                    .resizable()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.circle")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.gray)
            }

            // Change Image Button
            Button("Change Profile Image") {
                openImagePicker()
            }

            // Username Field (auto-save)
            TextField("Username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 200)
                .onChange(of: username) { newValue in
                    appState.saveUsername(newValue)
                }

            Spacer().frame(height: 40)

            // Logout Button
            Button(action: {
                appState.logout()
            }) {
                Text("Logout")
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 200)
                    .background(Color.red)
                    .cornerRadius(8)
            }
        }
        .padding()
        .onAppear {
            username = appState.currentUsername
        }
    }

    private func openImagePicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.png, .jpeg]

        panel.begin { response in
            if response == .OK, let selectedURL = panel.url {
                appState.saveProfileImageURL(selectedURL.absoluteString)
            }
        }
    }
}
