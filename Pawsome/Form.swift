import SwiftUI

#if os(macOS)
import AppKit
#else
import UIKit
#endif

struct FormView: View {
    #if os(macOS)
    var imageNS: NSImage?
    #else
    var imageUI: UIImage?
    #endif

    var body: some View {
        VStack {
            Text("Captured Image")
                .font(.largeTitle)
                .padding()

            #if os(macOS)
            if let image = imageNS {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 300, maxHeight: 300)
            } else {
                Text("No image captured.")
                    .foregroundColor(.gray)
            }
            #else
            if let image = imageUI {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 300, maxHeight: 300)
            } else {
                Text("No image captured.")
                    .foregroundColor(.gray)
            }
            #endif
        }
        .padding()
    }
}
