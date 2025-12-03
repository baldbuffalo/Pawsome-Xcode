import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class ProfileViewModel: ObservableObject {
    @Published var selectedImage: PlatformImage? = nil
    @Published var isImagePickerPresented = false

    var appState: PawsomeApp.AppState

    init(appState: PawsomeApp.AppState) {
        self.appState = appState
    }

    func saveUsername(_ username: String) {
        appState.saveUsername(username)
    }

    func saveProfileImage(_ img: PlatformImage, urlString: String? = nil) {
        selectedImage = img
        if let url = urlString {
            appState.saveProfileImageURL(url)
        }
        // Optional: upload image to Firebase Storage and get URL to save
    }
}

struct ProfileView: View {
    @ObservedObject var appState: PawsomeApp.AppState
    @StateObject private var vm: ProfileViewModel

    @State private var usernameTemp: String

    init(appState: PawsomeApp.AppState) {
        self.appState = appState
        _vm = StateObject(wrappedValue: ProfileViewModel(appState: appState))
        _usernameTemp = State(initialValue: appState.currentUsername)
    }

    var body: some View {
        VStack(spacing: 20) {
            // Profile Image
            Group {
                if let img = vm.selectedImage {
                    #if os(iOS)
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                    #elseif os(macOS)
                    Image(nsImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                    #endif
                } else if let urlStr = appState.profileImageURL, let url = URL(string: urlStr) {
                    AsyncImage(url: url) { img in
                        img.resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 120, height: 120)
                            .overlay(Text("Tap").foregroundColor(.gray))
                    }
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 120, height: 120)
                        .overlay(Text("Tap").foregroundColor(.gray))
                }
            }

            // Make image picker only show when user taps
            Button("Change Profile Image") {
                vm.isImagePickerPresented = true
            }
            .padding(.bottom, 20)

            // Username
            TextField("Enter username", text: $usernameTemp)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            // Save Button
            Button("Save Changes") {
                vm.saveUsername(usernameTemp)
            }
            .padding()
        }
        .padding()
        .onChange(of: usernameTemp) { oldValue, newValue in
            vm.saveUsername(newValue)
        }
        .sheet(isPresented: $vm.isImagePickerPresented) {
            PlatformImagePicker { img in
                vm.saveProfileImage(img)
            }
        }
    }
}

