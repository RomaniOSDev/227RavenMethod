import UIKit

enum PhotoDataCompressor {
    static func compress(data: Data, maxBytes: Int = 180_000) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let maxDimension: CGFloat = 900
        let size = image.size
        let scale = min(1, maxDimension / max(size.width, size.height))
        let targetSize = CGSize(width: size.width * scale, height: size.height * scale)

        UIGraphicsBeginImageContextWithOptions(targetSize, true, 1)
        image.draw(in: CGRect(origin: .zero, size: targetSize))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        guard let resized else { return nil }

        var quality: CGFloat = 0.82
        var jpeg = resized.jpegData(compressionQuality: quality)
        while let current = jpeg, current.count > maxBytes, quality > 0.35 {
            quality -= 0.08
            jpeg = resized.jpegData(compressionQuality: quality)
        }
        return jpeg
    }
}
