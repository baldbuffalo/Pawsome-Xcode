import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct FormView: View {

    @EnvironmentObject var appState: PawsomeApp.AppState
    @Binding var activeHomeFlow: PawsomeApp.HomeFlow?
    var onPostCreated: (() -> Void)?

    @State private var catName      = ""
    @State private var description  = ""
    @State private var age          = ""
    @State private var isPosting    = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // ── Header ──────────────────────────────────────────────
                HStack {
                    Button {
                        appState.selectedImage = nil
                        activeHomeFlow = nil
                    } label: {
                        Label("Back", systemImage: "chevron.left").font(.headline)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    Text("New Post").font(.headline)
                    Spacer()
                }
                .padding(.horizontal)

                // ── Preview image ────────────────────────────────────────
                if let image = appState.selectedImage {
                    previewImage(image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .frame(height: 240)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .padding(.horizontal)
                }

                // ── Fields ───────────────────────────────────────────────
                VStack(spacing: 14) {
                    FormField(icon: "pawprint.fill",  placeholder: "Cat Name",    text: $catName)
                    FormField(icon: "number",          placeholder: "Age (years)", text: $age)
                    #if os(iOS)
                        .keyboardType(.numberPad)
                    #endif
                    FormField(icon: "text.alignleft", placeholder: "Description", text: $description, axis: .vertical)
                }
                .padding(.horizontal)

                // ── Error ────────────────────────────────────────────────
                if let error = errorMessage {
                    Text(error)
                        .font(.footnote).foregroundColor(.red)
                        .padding(.horizontal).multilineTextAlignment(.center)
                }

                // ── Post button ───────────────────────────────────────────
                Button { Task { await submitPost() } } label: {
                    HStack {
                        if isPosting { ProgressView().tint(.white).padding(.trailing, 6) }
                        Text(isPosting ? "Uploading…" : "Post 🐾").font(.headline)
                    }
                    .frame(maxWidth: .infinity).padding()
                    .background(
                        isFormComplete && !isPosting
                            ? LinearGradient(colors: [.pink, .purple], startPoint: .leading, endPoint: .trailing)
                            : LinearGradient(colors: [.gray],          startPoint: .leading, endPoint: .trailing)
                    )
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                }
                .disabled(!isFormComplete || isPosting)
                .buttonStyle(.plain)
            }
            .padding(.vertical)
        }
        .onAppear { activeHomeFlow = .form }
    }

    // MARK: - Cross-platform image helper
    private func previewImage(_ image: PlatformImage) -> Image {
        #if os(iOS)
        return Image(uiImage: image)
        #else
        return Image(nsImage: image)
        #endif
    }

    // MARK: - Submit (all logic inline)
    private func submitPost() async {
        guard
            isFormComplete,
            let image = appState.selectedImage,
            let uid   = Auth.auth().currentUser?.uid
        else { return }

        isPosting    = true
        errorMessage = nil

        do {
            // 1. Upload image → GitHub pawsome-assets/postImages/
            let resized  = image.resizedForUpload(maxDimension: 1200)
            let filename = "\(uid)_\(Int(Date().timeIntervalSince1970)).jpg"
            let imageURL = try await GitHubUploader.shared.uploadImage(
                resized, filename: filename, folder: "postImages"
            )

            // 2. Grab author's profile pic
            let userSnap   = try? await Firestore.firestore().collection("users").document(uid).getDocument()
            let profilePic = userSnap?.data()?["profilePic"] as? String ?? ""

            // 3. Save post to Firestore
            try await Firestore.firestore().collection("posts").addDocument(data: [
                "catName":         catName.trimmingCharacters(in: .whitespacesAndNewlines),
                "description":     description.trimmingCharacters(in: .whitespacesAndNewlines),
                "age":             age.trimmingCharacters(in: .whitespacesAndNewlines),
                "imageURL":        imageURL,
                "ownerUID":        uid,
                "ownerUsername":   appState.currentUsername,
                "ownerProfilePic": profilePic,
                "timestamp":       Timestamp(),
                "likes":           [String](),
                "commentCount":    0
            ])

            appState.selectedImage = nil
            activeHomeFlow         = nil
            onPostCreated?()

        } catch {
            errorMessage = error.localizedDescription
        }

        isPosting = false
    }

    private var isFormComplete: Bool {
        !catName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !age.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        appState.selectedImage != nil
    }
}

// MARK: - Reusable field
private struct FormField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var axis: Axis = .horizontal

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.purple).frame(width: 20)
                .padding(.top, axis == .vertical ? 12 : 0)
            TextField(placeholder, text: $text, axis: axis)
                .textFieldStyle(.plain)
                .padding(12)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .lineLimit(axis == .vertical ? 3...6 : 1...1)
        }
    }
}
