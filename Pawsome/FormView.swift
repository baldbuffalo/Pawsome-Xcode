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

                // Image preview
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

                TextField("Last Seen Location", text: $lastSeenLocation)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(true)
                    .padding(.vertical, 5)

                Button("Post 🐾") {
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

    // 🔢 Numbers only + max 2 digits
    private func inputNumberField(_ placeholder: String, _ binding: Binding<String>) -> some View {
        TextField(placeholder, text: binding)
            #if os(iOS)
            .keyboardType(.numberPad)
            #endif
            .onChange(of: binding.wrappedValue) { _, newValue in
                let filtered = newValue.filter { $0.isNumber }
                let limited = String(filtered.prefix(2))
                if limited != newValue {
                    binding.wrappedValue = limited
                }
            }
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding(.vertical, 5)
    }
}
