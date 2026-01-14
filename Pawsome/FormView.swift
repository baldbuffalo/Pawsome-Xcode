import SwiftUI

struct FormView: View {

    // 🔑 GLOBAL STATE
    @EnvironmentObject var appState: PawsomeApp.AppState
    @Binding var activeHomeFlow: PawsomeApp.HomeFlow?

    var onPostCreated: (() -> Void)?

    @State private var catName = ""
    @State private var description = ""
    @State private var age = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                // 🖼️ IMAGE FROM APPSTATE
                if let image = appState.selectedImage {
                    #if os(iOS)
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 220)
                    #else
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 220)
                    #endif
                }

                TextField("Cat Name", text: $catName)
                    .textFieldStyle(.roundedBorder)

                TextField("Age", text: $age)
                    .textFieldStyle(.roundedBorder)
                    #if os(iOS)
                    .keyboardType(.numberPad)
                    #endif

                TextField("Description", text: $description)
                    .textFieldStyle(.roundedBorder)

                Button("Post 🐾") {
                    // ✅ RESET FLOW
                    appState.selectedImage = nil
                    activeHomeFlow = nil
                    onPostCreated?()
                }
                .disabled(!isFormComplete)
                .buttonStyle(.borderedProminent)
                .padding(.top)
            }
            .padding()
        }
        .onAppear {
            activeHomeFlow = .form
        }
    }

    private var isFormComplete: Bool {
        !catName.isEmpty && !description.isEmpty && !age.isEmpty
    }
}
