import SwiftUI

// Separate FormView in Form.swift
struct Form: View {
    var imageUI: UIImage?

    var body: some View {
        VStack {
            if let image = imageUI {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 300)
            } else {
                Text("No image available")
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Captured Image")
    }
}
