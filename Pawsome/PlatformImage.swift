#if os(iOS)
import UIKit
typealias PlatformImage = UIImage
#elseif os(macOS)
import AppKit
typealias PlatformImage = NSImage
#endif

extension PlatformImage {
    func pngDataCompat() -> Data? {
        #if os(iOS)
        return self.pngData()
        #else
        guard
            let tiff = self.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiff)
        else { return nil }
        return bitmap.representation(using: .png, properties: [:])
        #endif
    }
}
