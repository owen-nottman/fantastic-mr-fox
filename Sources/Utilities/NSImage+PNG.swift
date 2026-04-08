import AppKit

extension NSImage {
    /// Returns compressed PNG data, scaling down the image if it exceeds `maxBytes`.
    ///
    /// - Parameter maxBytes: Maximum byte size for the PNG. Claude's vision API recommends
    ///   keeping images under ~1.5 MB for fast responses.
    func pngData(maxBytes: Int = 1_500_000) -> Data? {
        guard let tiff = tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff) else { return nil }

        var data = rep.representation(using: .png, properties: [:])

        // Scale down if over the limit, preserving aspect ratio
        if let d = data, d.count > maxBytes {
            let scale = sqrt(Double(maxBytes) / Double(d.count))
            let newSize = NSSize(width: size.width * scale, height: size.height * scale)
            let scaled = NSImage(size: newSize)
            scaled.lockFocus()
            draw(in: NSRect(origin: .zero, size: newSize),
                 from: .zero,
                 operation: .copy,
                 fraction: 1.0)
            scaled.unlockFocus()

            if let tiff2 = scaled.tiffRepresentation,
               let rep2 = NSBitmapImageRep(data: tiff2) {
                data = rep2.representation(using: .png, properties: [:])
            }
        }

        return data
    }
}
