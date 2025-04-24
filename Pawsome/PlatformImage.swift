#if os(iOS)
import UIKit
typealias PlatformImage = UIImage

extension PlatformImage {
    func asPNGData() -> Data? {
        self.pngData()
    }
}
#elseif os(macOS)
import AppKit
typealias PlatformImage = NSImage

extension PlatformImage {
    func asPNGData() -> Data? {
        guard let tiffData = self.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        return bitmap.representation(using: .png, properties: [:])
    }
}
#endif
