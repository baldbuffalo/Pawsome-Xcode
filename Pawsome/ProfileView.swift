import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ProfileView: View {

    @ObservedObject var appState: PawsomeApp.AppState
    @State private var isUpdating = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // MARK: - Profile Image
                ZStack {
                    if let urlString = appState.profileImageURL,
                       let url = URL(string: urlString),
                       !urlString.isEmpty {

                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())

                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 120, height: 120)
                            .foregroundColor(.gray)
                    }
                }

                // MARK: - Username
                Text(appState.currentUsername)
                    .font(.title2)
                    .bold()

                // MARK: - Email
                if let email = Auth.auth().currentUser?.email {
                    Text(email)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                Divider().padding(.vertical)

                // MARK: - Change Profile Picture (URL-based)
                Button {
                    updateProfilePictureFromAuthProvider()
                } label: {
                    Label("Sync Profile Picture", systemImage: "arrow.clockwise")
                }
                .disabled(isUpdating)

                // MARK: - Logout
                Button(role: .destructive) {
                    appState.logout()
                } label: {
                    Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                }

                // MARK: - Error
                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                }
            }
            .padding()
        }
    }

    // MARK: - Pull profile pic from Google / Apple account
    private func updateProfilePictureFromAuthProvider() {
        guard let user = Auth.auth().currentUser else { return }

        let newURL = user.photoURL?.absoluteString ?? ""

        // person.circle.fill state → don't save empty
        guard !newURL.isEmpty else { return }

        isUpdating = true
        errorMessage = nil

        let uid = user.uid
        let userRef = Firestore.firestore().collection("users").document(uid)

        userRef.updateData([
            "profilePic": newURL
        ]) { error in
            isUpdating = false

            if let error {
                errorMessage = error.localizedDescription
                return
            }

            appState.profileImageURL = newURL
            UserDefaults.standard.set(newURL, forKey: "profileImageURL")
        }
    }
}
