#if os(iOS)
import UIKit
public typealias PlatformImage = UIImage

public extension PlatformImage {
    func toPNGData() -> Data? {
        return self.pngData()
    }
}
#elseif os(macOS)
import AppKit
public typealias PlatformImage = NSImage

public extension PlatformImage {
    func toPNGData() -> Data? {
        guard let tiffData = self.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else { return nil }
        return bitmap.representation(using: .png, properties: [:])
    }
}
#endif
