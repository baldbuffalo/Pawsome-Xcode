import SwiftUI

struct FormView: View {
    var image: PlatformImage
    var username: String
    var onPostCreated: (() -> Void)?

    @Binding var activeHomeFlow: PawsomeApp.HomeFlow?

    @State private var catName = ""
    @State private var description = ""
    @State private var age = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 15) {

                #if os(iOS)
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                #else
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                #endif

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
                    onPostCreated?()
                }
                .disabled(!isFormComplete)
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
