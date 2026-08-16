import UIKit

/// Photos imported from the library are written to disk as JPEGs and referenced
/// by filename. Keeping the bytes out of the JSON state file matters: a board
/// with fifty photos would otherwise produce a multi-megabyte document that has
/// to be re-encoded on every drag.
enum ImageStore {

    private static var cache = NSCache<NSString, UIImage>()

    static var directory: URL {
        let base = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Memories/Images", isDirectory: true)

        if !FileManager.default.fileExists(atPath: base.path) {
            try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        }
        return base
    }

    static func url(for name: String) -> URL {
        directory.appendingPathComponent(name)
    }

    /// Writes image data, downscaling to a sensible board size first.
    /// Returns the filename to store on the model, or `nil` if the data was not
    /// a decodable image.
    @discardableResult
    static func save(data: Data) -> String? {
        guard let image = UIImage(data: data) else { return nil }

        let resized = downscale(image, maxDimension: 1600)
        guard let jpeg = resized.jpegData(compressionQuality: 0.85) else { return nil }

        let name = "\(UUID().uuidString).jpg"
        do {
            try jpeg.write(to: url(for: name), options: .atomic)
            cache.setObject(resized, forKey: name as NSString)
            return name
        } catch {
            return nil
        }
    }

    static func image(named name: String) -> UIImage? {
        if let cached = cache.object(forKey: name as NSString) {
            return cached
        }
        // The user's own imports live on disk under Application Support; the
        // demo board's photographs live in the asset catalogue. A given name
        // only ever resolves to one of the two, and the user's file wins.
        var found = UIImage(contentsOfFile: url(for: name).path)
        if found == nil {
            found = UIImage(named: (name as NSString).deletingPathExtension)
        }

        guard let resolved = found else {
            return nil
        }

        cache.setObject(resolved, forKey: name as NSString)
        return resolved
    }

    static func delete(named name: String) {
        cache.removeObject(forKey: name as NSString)
        try? FileManager.default.removeItem(at: url(for: name))
    }

    private static func downscale(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let longest = max(image.size.width, image.size.height)
        guard longest > maxDimension else { return image }

        let scale = maxDimension / longest
        let target = CGSize(width: image.size.width * scale, height: image.size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: target)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
    }
}
