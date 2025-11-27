import SwiftUI
import FirebaseFirestore
import FirebaseAuth

// Reference PlatformImage.swift for UIImage/NSImage alias
// #if os(iOS)
// import UIKit
// public typealias PlatformImage = UIImage
// #elseif os(macOS)
// import AppKit
// public typealias PlatformImage = NSImage
// #endif

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var username: String
    @Published var profileImageURL: String?
    @Published var selectedImage: PlatformImage?
    @Published var isImageLoading = false
    @Published var isSaving = false
    @Published var isImagePickerPresented = false
    @Published var isLoading = false

    private var typingWorkItem: Task<Void, Never>?
    private let firestore = Firestore.firestore()
    private var userId: String? {
        Auth.auth().currentUser?.uid
    }

    init(username: String) {
        self.username = username
    }

    func loadProfile() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isLoading = false
            self.username = UserDefaults.standard.string(forKey: "username") ?? self.username
            self.profileImageURL = UserDefaults.standard.string(forKey: "profileImageURL")
        }
    }

    func userTyping() {
        // Cancel previous typing task
        typingWorkItem?.cancel()

        isSaving = true // Show "Saving..." while typing

        // Save immediately to Firebase
        Task {
            await saveToFirebase()
        }

        // Create new delay task for detecting stopped typing
        typingWorkItem = Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5s after last keystroke
            await userStoppedTyping()
        }
    }

    private func userStoppedTyping() async {
        // Only show "Saved" after Firebase finishes saving
        await saveToFirebase()
        isSaving = false
    }

    private func saveToFirebase() async {
        guard let uid = userId else { return }
        do {
            try await firestore.collection("users").document(uid).setData([
                "username": username
            ], merge: true)
            UserDefaults.standard.set(username, forKey: "username")
        } catch {
            print("Firebase save error: \(error)")
        }
    }

    func uploadProfileImage(image: PlatformImage) async {
        isImageLoading = true

        #if os(iOS)
        if let data = image.pngData() {
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("profile.png")
            try? data.write(to: url)
            profileImageURL = url.absoluteString
            UserDefaults.standard.set(profileImageURL, forKey: "profileImageURL")
        }
        #elseif os(macOS)
        if let tiff = image.tiffRepresentation,
           let data = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:]) {
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("profile.png")
            try? data.write(to: url)
            profileImageURL = url.absoluteString
            UserDefaults.standard.set(profileImageURL, forKey: "profileImageURL")
        }
        #endif

        isImageLoading = false
    }
}

struct ProfileView: View {
    @Binding var isLoggedIn: Bool
    @Binding var currentUsername: String
    @Binding var profileImageURL: String?

    @StateObject private var vm: ProfileViewModel
    @FocusState private var usernameFocused: Bool

    init(isLoggedIn: Binding<Bool>, currentUsername: Binding<String>, profileImageURL: Binding<String?>) {
        self._isLoggedIn = isLoggedIn
        self._currentUsername = currentUsername
        self._profileImageURL = profileImageURL
        _vm = StateObject(wrappedValue: ProfileViewModel(username: currentUsername.wrappedValue))
    }

    var body: some View {
        VStack(spacing: 16) {
            if vm.isLoading {
                ProgressView("Loading Profile...").padding()
            }

            // Profile Image
            if let selectedImage = vm.selectedImage {
                #if os(iOS)
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                #elseif os(macOS)
                Image(nsImage: selectedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                #endif
            } else if let urlString = vm.profileImageURL ?? profileImageURL,
                      let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image.resizable().scaledToFit()
                    case .failure:
                        defaultImage()
                    @unknown default:
                        defaultImage()
                    }
                }
                .frame(width: 120, height: 120)
                .clipShape(Circle())
            } else {
                defaultImage()
            }

            // Username field
            TextField("Username", text: $vm.username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .focused($usernameFocused)
                .onChange(of: vm.username) { _ in
                    vm.userTyping()
                }

            Text(vm.isSaving ? "Saving..." : "Saved")
                .foregroundColor(vm.isSaving ? .gray : .green)
                .font(.caption)

            Button("Change Profile Picture") {
                vm.isImagePickerPresented = true
            }

            Button(role: .destructive) {
                currentUsername = ""
                profileImageURL = nil
                UserDefaults.standard.removeObject(forKey: "username")
                UserDefaults.standard.removeObject(forKey: "profileImageURL")
                UserDefaults.standard.set(false, forKey: "isLoggedIn")
                isLoggedIn = false
            } label: {
                Text("Log Out").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)

            Spacer()
        }
        .padding()
        .onAppear { vm.loadProfile() }
        .sheet(isPresented: $vm.isImagePickerPresented) {
            ImagePickerView(selectedImage: $vm.selectedImage)
                .onDisappear {
                    if let image = vm.selectedImage {
                        Task { await vm.uploadProfileImage(image: image) }
                    }
                }
        }
    }

    @ViewBuilder
    private func defaultImage() -> some View {
        Image(systemName: "person.crop.circle.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 120, height: 120)
            .foregroundColor(.gray)
    }
}
