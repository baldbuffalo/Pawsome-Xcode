import SwiftUI
import FirebaseAuth
import FirebaseFirestore

#if os(iOS)
import UIKit
typealias PlatformImage = UIImage
#elseif os(macOS)
import AppKit
typealias PlatformImage = NSImage
#endif

struct ProfileView: View {

    @ObservedObject var appState: PawsomeApp.AppState

    @State private var username: String = ""
    @State private var saveStatus = ""
    @State private var isTyping = false

    @State private var showPicker = false
    @State private var pickedImage: PlatformImage?

    var body: some View {
        VStack(spacing: 30) {

            // MARK: - Profile Image
            Button {
                showPicker = true
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
        .onAppear {
            username = appState.currentUsername
        }
        .fileImporter(
            isPresented: $showPicker,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false,
            onCompletion: handleImagePick
        )
    }

    // MARK: - Profile Image UI
    @ViewBuilder
    private func profileImageView() -> some View {
        if let urlString = appState.profileImageURL,
           let url = URL(string: urlString),
           !urlString.isEmpty {

            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
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

        } else {
            Image(systemName: "person.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundColor(.gray)
        }
    }

    // MARK: - Image Picker Handler
    private func handleImagePick(result: Result<[URL], Error>) {
        guard
            case .success(let urls) = result,
            let fileURL = urls.first,
            let image = loadImage(from: fileURL),
            let uid = Auth.auth().currentUser?.uid
        else { return }

        Task {
            do {
                let data = imageData(from: image)
                let uploader = GitHubUploader()

                let downloadURL = try await uploader.uploadImage(
                    filename: "\(uid).jpg",
                    imageData: data
                )

                await MainActor.run {
                    appState.profileImageURL = downloadURL
                }

                try await Firestore.firestore()
                    .collection("users")
                    .document(uid)
                    .updateData([
                        "profilePic": downloadURL
                    ])

            } catch {
                print("❌ Image upload failed:", error)
            }
        }
    }

    // MARK: - Username Save
    private func saveUsername() {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let uid = Auth.auth().currentUser?.uid
        else { return }

        saveStatus = "Saving..."

        Firestore.firestore()
            .collection("users")
            .document(uid)
            .updateData(["username": trimmed]) { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    if !isTyping {
                        saveStatus = "Saved"
                        appState.currentUsername = trimmed
                    }
                }
            }
    }

    // MARK: - Helpers
    private func loadImage(from url: URL) -> PlatformImage? {
        #if os(iOS)
        return UIImage(contentsOfFile: url.path)
        #else
        return NSImage(contentsOf: url)
        #endif
    }

    private func imageData(from image: PlatformImage) -> Data {
        #if os(iOS)
        return image.jpegData(compressionQuality: 0.8)!
        #else
        let tiff = image.tiffRepresentation!
        let rep = NSBitmapImageRep(data: tiff)!
        return rep.representation(using: .jpeg, properties: [:])!
        #endif
    }
}
