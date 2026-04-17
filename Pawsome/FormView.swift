import SwiftUI
import FirebaseAuth

struct FormView: View {

    @EnvironmentObject var appState: PawsomeApp.AppState
    @Binding var activeHomeFlow: PawsomeApp.HomeFlow?

    var onPostCreated: (() -> Void)?

    @State private var catName    = ""
    @State private var description = ""
    @State private var age        = ""

    @State private var isPosting  = false
    @State private var errorMessage: String?

    private let postsVM = PostsViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // ── Header ──────────────────────────────────────────────
                HStack {
                    Button {
                        appState.selectedImage = nil
                        activeHomeFlow = nil
                    } label: {
                        Label("Back", systemImage: "chevron.left")
                            .font(.headline)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    Text("New Post")
                        .font(.headline)
                    Spacer()
                }
                .padding(.horizontal)

                // ── Preview Image ────────────────────────────────────────
                if let image = appState.selectedImage {
                    #if os(iOS)
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 240)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .padding(.horizontal)
                    #else
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 240)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .padding(.horizontal)
                    #endif
                }

                // ── Fields ───────────────────────────────────────────────
                VStack(spacing: 14) {
                    FormField(icon: "pawprint.fill", placeholder: "Cat Name",    text: $catName)
                    FormField(icon: "number",         placeholder: "Age (years)", text: $age)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                    FormField(icon: "text.alignleft", placeholder: "Description", text: $description, axis: .vertical)
                }
                .padding(.horizontal)

                // ── Error ────────────────────────────────────────────────
                if let error = errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }

                // ── Post Button ──────────────────────────────────────────
                Button {
                    Task { await submitPost() }
                } label: {
                    HStack {
                        if isPosting {
                            ProgressView()
                                .tint(.white)
                                .padding(.trailing, 6)
                        }
                        Text(isPosting ? "Posting…" : "Post 🐾")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFormComplete && !isPosting
                        ? LinearGradient(colors: [.pink, .purple], startPoint: .leading, endPoint: .trailing)
                        : LinearGradient(colors: [.gray], startPoint: .leading, endPoint: .trailing)
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

    // MARK: - Submit
    private func submitPost() async {
        guard
            isFormComplete,
            let image = appState.selectedImage,
            let uid   = Auth.auth().currentUser?.uid
        else { return }

        isPosting     = true
        errorMessage  = nil

        do {
            try await postsVM.createPost(
                catName:        catName,
                description:    description,
                age:            age,
                image:          image,
                authorUID:      uid,
                authorUsername: appState.currentUsername
            )

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

// MARK: - Reusable Form Field
private struct FormField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var axis: Axis = .horizontal

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.purple)
                .frame(width: 20)
                .padding(.top, axis == .vertical ? 12 : 0)

            TextField(placeholder, text: $text, axis: axis)
                .textFieldStyle(.plain)
                .padding(12)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .lineLimit(axis == .vertical ? 3...6 : 1)
        }
    }
}
