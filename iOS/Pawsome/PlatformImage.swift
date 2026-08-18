#if os(iOS)
import UIKit
typealias PlatformImage = UIImage
#elseif os(macOS)
import AppKit
typealias PlatformImage = NSImage
#endif

extension PlatformImage {

    // PNG
    func pngDataCompat() -> Data? {
        #if os(iOS)
        return self.pngData()
        #else
        guard
            let tiff   = self.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiff)
        else { return nil }
        return bitmap.representation(using: .png, properties: [:])
        #endif
    }

    // JPEG  (used by GitHubUploader)
    func jpegDataCompat(quality: CGFloat = 0.8) -> Data? {
        #if os(iOS)
        return self.jpegData(compressionQuality: quality)
        #else
        guard
            let tiff   = self.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiff)
        else { return nil }
        return bitmap.representation(
            using: .jpeg,
            properties: [.compressionFactor: quality]
        )
        #endif
    }

    // Resizes to `maxDimension` before encoding — keeps uploads small
    func resizedForUpload(maxDimension: CGFloat = 1200) -> PlatformImage {
        #if os(iOS)
        let size = self.size
        let scale = min(maxDimension / max(size.width, size.height), 1)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in self.draw(in: CGRect(origin: .zero, size: newSize)) }

        #else
        let size = self.size
        let scale = min(maxDimension / max(size.width, size.height), 1)
        let newSize = NSSize(width: size.width * scale, height: size.height * scale)
        let resized = NSImage(size: newSize)
        resized.lockFocus()
        self.draw(in: NSRect(origin: .zero, size: newSize))
        resized.unlockFocus()
        return resized
        #endif
    }
}
