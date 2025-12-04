import SwiftUI
import CoreLocation
import ImageIO

struct FormView: View {
    @Binding var showForm: Bool
    @Binding var navigateToHome: Bool
    var image: PlatformImage
    var username: String
    var onPostCreated: (() -> Void)?

    @State private var catName = ""
    @State private var catDescription = ""
    @State private var catAge = ""
    @State private var lastSeenLocation = ""
    @State private var imageURL = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                #if os(iOS)
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .cornerRadius(10)
                    .onAppear { extractLocation() }
                #elseif os(macOS)
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .cornerRadius(10)
                    .onAppear { extractLocation() }
                #endif

                inputField("Cat Name", $catName)
                inputField("Description", $catDescription)

                // Age input with number-only handling
                inputField("How old is the cat?", $catAge)
                    #if os(iOS)
                    .keyboardType(.numberPad)
                    #elseif os(macOS)
                    .onChange(of: catAge, initial: false) { oldValue, newValue in
                        catAge = newValue.filter { $0.isNumber }
                    }
                    #endif

                // Last Seen Location (auto, not editable)
                HStack {
                    Text("Last Seen Location")
                        .foregroundColor(.gray)
                    Spacer()
                    Text(lastSeenLocation.isEmpty ? "Fetching..." : lastSeenLocation)
                        .foregroundColor(.blue)
                }
                .padding(.vertical, 5)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(5)

                inputField("Image URL (optional)", $imageURL)

                Button("Post 🐾") {
                    catName = ""
                    catDescription = ""
                    catAge = ""
                    lastSeenLocation = ""
                    imageURL = ""
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
        !catName.isEmpty && !catDescription.isEmpty && !catAge.isEmpty && !lastSeenLocation.isEmpty
    }

    private func inputField(_ placeholder: String, _ binding: Binding<String>) -> some View {
        TextField(placeholder, text: binding)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding(.vertical, 5)
    }

    // MARK: - Extract GPS location from image
    private func extractLocation() {
        #if os(iOS)
        guard let cgImage = image.cgImage else { return }
        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(data as CFMutableData, kUTTypeJPEG, 1, nil)
        CGImageDestinationAddImage(destination!, cgImage, nil)
        CGImageDestinationFinalize(destination!)
        if let source = CGImageSourceCreateWithData(data, nil),
           let metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any],
           let gps = metadata[kCGImagePropertyGPSDictionary as String] as? [String: Any],
           let lat = gps[kCGImagePropertyGPSLatitude as String] as? Double,
           let lon = gps[kCGImagePropertyGPSLongitude as String] as? Double {
            let location = CLLocation(latitude: lat, longitude: lon)
            let geoCoder = CLGeocoder()
            geoCoder.reverseGeocodeLocation(location) { placemarks, _ in
                if let placemark = placemarks?.first {
                    lastSeenLocation = [placemark.locality, placemark.subLocality]
                        .compactMap { $0 }
                        .joined(separator: ", ")
                }
            }
        }
        #elseif os(macOS)
        // TODO: macOS image GPS extraction (similar using CGImageSource)
        lastSeenLocation = "macOS location not implemented"
        #endif
    }
}
