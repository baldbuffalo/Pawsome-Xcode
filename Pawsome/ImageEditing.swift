import SwiftUI

struct ImageEditing: View {
    var image: UIImage

    var body: some View {
        VStack {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Button(action: {
                // Image editing functionality (e.g., cropping, filters, etc.)
                print("Edit button tapped")
            }) {
                Text("Edit")
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding()

            Button(action: {
                // Dismiss the view after editing
                dismissView()
            }) {
                Text("Done")
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.green)
                    .cornerRadius(10)
            }
            .padding()
        }
    }

    private func dismissView() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            if let window = windowScene.windows.first {
                window.rootViewController?.dismiss(animated: true, completion: nil)
            }
        }
    }
}
