import SwiftUI
import CoreLocation

struct FormView: View {
    @Binding var showForm: Bool
    @Binding var navigateToHome: Bool
    var image: PlatformImage
    var username: String
    var onPostCreated: (() -> Void)?

    @State private var catName = ""
    @State private var description = ""
    @State private var age = ""
    @State private var lastSeenLocation = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                // Display the image
                #if os(iOS)
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .cornerRadius(10)
                #elseif os(macOS)
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .cornerRadius(10)
                #endif

                inputField("Cat Name", $catName)
                inputNumberField("How old is the cat?", $age)
                inputField("Description", $description)

                // Last seen location field (read-only)
                TextField("Last Seen Location", text: $lastSeenLocation)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(true)
                    .padding(.vertical, 5)

                Button("Post 🐾") {
                    // Reset form & call closure
                    catName = ""
                    description = ""
                    age = ""
                    lastSeenLocation = ""
                    showForm = false
                    navigateToHome = true
                    onPostCreated?()
                }
                .disabled(!isFormComplete)
                .foregroundColor(isFormComplete ? .blue : .gray)
                .padding(.top)
            }
            .padding()
            .onAppear {
                // TODO: fetch location for lastSeenLocation if macOS
            }
        }
    }

    private var isFormComplete: Bool {
        !catName.isEmpty && !description.isEmpty && !age.isEmpty
    }

    private func inputField(_ placeholder: String, _ binding: Binding<String>) -> some View {
        TextField(placeholder, text: binding)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding(.vertical, 5)
    }

    private func inputNumberField(_ placeholder: String, _ binding: Binding<String>) -> some View {
        #if os(iOS)
        return TextField(placeholder, text: binding)
            .keyboardType(.numberPad)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding(.vertical, 5)
        #elseif os(macOS)
        return TextField(placeholder, text: binding)
            .onChange(of: binding.wrappedValue) { oldValue, newValue in
                let filtered = newValue.filter { "0123456789".contains($0) }
                if filtered != newValue {
                    binding.wrappedValue = filtered
                }
            }
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding(.vertical, 5)
        #endif
    }
}
