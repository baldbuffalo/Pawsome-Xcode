import SwiftUI
import PhotosUI
import FirebaseAuth
import FirebaseFirestore

struct FormView: View {
    @EnvironmentObject var appState: PawsomeApp.AppState
    @Binding var activeHomeFlow: PawsomeApp.HomeFlow?
    var onPostCreated: (() -> Void)?

    @State private var catName = ""
    @State private var age = ""
    @State private var description = ""
    @State private var location = ""
    @State private var selectedStatus: PostStatus = .LOST
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var isPosting = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                HStack {
                    Button { close() } label: {
                        Image(systemName: "chevron.left").font(.headline)
                    }
                    Spacer()
                    Text("Create Post").font(.title3.bold())
                    Spacer()
                    Color.clear.frame(width: 32)
                }
                .padding(.horizontal)
                .padding(.top, 8)

                VStack(alignment: .leading, spacing: 12) {
                    Text("What's the status?").font(.headline)
                    HStack(spacing: 12) {
                        ForEach(PostStatus.allCases.filter { $0 != .REUNITED }) { status in
                            Button { selectedStatus = status } label: {
                                VStack(spacing: 4) {
                                    Text(status.emoji).font(.system(size: 32))
                                    Text(status.displayName).font(.subheadline.weight(.semibold))
                                }
                                .frame(maxWidth: .infinity, minHeight: 90)
                                .foregroundStyle(selectedStatus == status ? .white : status == .LOST ? .red : .green)
                                .background(selectedStatus == status ? (status == .LOST ? Color.red : Color.green) : Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(status == .LOST ? Color.red.opacity(0.3) : Color.green.opacity(0.3), lineWidth: selectedStatus == status ? 0 : 2))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal)

                if let data = imageData, let image = PlatformImage(data: data) {
                    ZStack(alignment: .topTrailing) {
                        platformImage(image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .frame(height: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        Button { imageData = nil; selectedPhoto = nil } label: {
                            Image(systemName: "xmark")
                                .foregroundStyle(.white)
                                .padding(9)
                                .background(.black.opacity(0.6), in: Circle())
                        }
                        .padding(8)
                    }
                    .padding(.horizontal)
                } else {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        VStack(spacing: 8) {
                            Image(systemName: "photo.badge.plus").font(.system(size: 42))
                            Text("Add a photo of the cat").foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 180)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal)
                }

                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Label(imageData == nil ? "Choose Image" : "Change Image", systemImage: imageData == nil ? "photo.badge.plus" : "arrow.clockwise")
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
                .buttonStyle(.bordered)
                .padding(.horizontal)

                VStack(spacing: 14) {
                    FormField(icon: "pawprint.fill", title: "Cat Name", text: $catName)
                    FormField(icon: "birthday.cake.fill", title: "Age (years)", text: $age, keyboard: .numberPad)
                        .onChange(of: age) { _, value in
                            let digits = value.filter { $0.isNumber }
                            age = String(digits.prefix(2))
                        }
                    FormField(icon: "mappin.and.ellipse", title: "Location (optional)", text: $location)
                    FormField(icon: "doc.text", title: "Description", text: $description, axis: .vertical)
                }
                .padding(.horizontal)

                if let errorMessage {
                    Text(errorMessage).font(.footnote).foregroundStyle(.red).padding(.horizontal)
                }

                Button { Task { await submitPost() } } label: {
                    Group {
                        if isPosting { ProgressView().tint(.white) }
                        else { Label("Post \(selectedStatus.emoji)", systemImage: "paperplane.fill") }
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 56)
                }
                .buttonStyle(.borderedProminent)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .disabled(!isComplete || isPosting)
                .padding(.horizontal)

                Spacer(minLength: 32)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color(.systemBackground))
        .onChange(of: selectedPhoto) { _, item in
            guard let item else { return }
            Task {
                imageData = try? await item.loadTransferable(type: Data.self)
            }
        }
    }

    private var isComplete: Bool {
        !catName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !age.isEmpty && !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && imageData != nil
    }

    private func close() {
        imageData = nil
        selectedPhoto = nil
        appState.selectedImage = nil
        activeHomeFlow = nil
    }

    private func platformImage(_ image: PlatformImage) -> Image {
        #if os(iOS)
        Image(uiImage: image)
        #else
        Image(nsImage: image)
        #endif
    }

    private func submitPost() async {
        guard isComplete, let data = imageData, let uid = Auth.auth().currentUser?.uid, let userID = appState.currentUserID else { return }
        isPosting = true
        errorMessage = nil
        do {
            guard let image = PlatformImage(data: data) else { throw NSError(domain: "Pawsome", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not read image."]) }
            let resized = image.resizedForUpload(maxDimension: 1200)
            let filename = "\(uid)_\(Int(Date().timeIntervalSince1970)).jpg"
            let imageURL = try await GitHubUploader.shared.uploadImage(resized, filename: filename, folder: "postImages")
            let userSnap = try await Firestore.firestore().collection("users").document(uid).getDocument()
            let data = userSnap.data() ?? [:]
            let username = data["Username"] as? String ?? appState.currentUsername
            let profilePic = data["ProfilePic"] as? String ?? ""

            try await Firestore.firestore().collection("posts").addDocument(data: [
                "CatName": catName.trimmingCharacters(in: .whitespacesAndNewlines),
                "CatAge": age,
                "description": description.trimmingCharacters(in: .whitespacesAndNewlines),
                "location": location.trimmingCharacters(in: .whitespacesAndNewlines),
                "status": selectedStatus.rawValue,
                "imageURL": imageURL,
                "UserID": userID,
                "Username": username,
                "ProfilePic": profilePic,
                "PostedAt": FieldValue.serverTimestamp(),
                "likes": [String](),
                "commentCount": 0
            ])
            appState.selectedImage = nil
            imageData = nil
            selectedPhoto = nil
            activeHomeFlow = nil
            onPostCreated?()
        } catch {
            errorMessage = error.localizedDescription
        }
        isPosting = false
    }
}

private struct FormField: View {
    let icon: String
    let title: String
    @Binding var text: String
    var axis: Axis = .horizontal
    var keyboard: UIKeyboardType = .default

    var body: some View {
        HStack(alignment: axis == .vertical ? .top : .center, spacing: 10) {
            Image(systemName: icon).frame(width: 22).foregroundStyle(.tint)
            TextField(title, text: $text, axis: axis)
                .textFieldStyle(.roundedBorder)
                .keyboardType(keyboard)
                .textInputAutocapitalization(.sentences)
                .lineLimit(axis == .vertical ? 3...6 : 1)
        }
    }
}
