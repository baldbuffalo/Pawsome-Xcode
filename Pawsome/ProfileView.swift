import SwiftUI

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var username: String
    @Published var profileImageURL: String?
    @Published var selectedImage: PlatformImage?
    @Published var isImageLoading = false
    @Published var isSaving = false
    @Published var isImagePickerPresented = false
    @Published var isLoading = false
    @Published var hasEdited = false // track if user started typing
    
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
    
    func saveUsername() {
        guard !username.isEmpty else { return }
        isSaving = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            UserDefaults.standard.set(self.username, forKey: "username")
            self.isSaving = false
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
            
            // Profile image
            let imageURLString = vm.selectedImage == nil ? (vm.profileImageURL ?? profileImageURL) : nil
            
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
            } else if let urlString = imageURLString, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image.resizable().scaledToFit()
                    case .failure:
                        Image(systemName: "person.crop.circle.fill").resizable().scaledToFit()
                    @unknown default:
                        Image(systemName: "person.crop.circle.fill").resizable().scaledToFit()
                    }
                }
                .frame(width: 120, height: 120)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 120, height: 120)
                    .foregroundColor(.gray)
            }
            
            // Username field
            TextField("Username", text: $vm.username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .focused($usernameFocused)
                .onChange(of: vm.username) { oldValue, newValue in
                    vm.hasEdited = true
                    vm.saveUsername()
                    currentUsername = newValue
                }
            
            // Save/Saving indicator
            if vm.hasEdited {
                Text(vm.isSaving ? "Saving..." : "Saved")
                    .foregroundColor(vm.isSaving ? .gray : .green)
                    .font(.caption)
            }
            
            // Change profile picture button
            Button("Change Profile Picture") {
                vm.isImagePickerPresented = true
            }
            
            // Logout button
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
}

