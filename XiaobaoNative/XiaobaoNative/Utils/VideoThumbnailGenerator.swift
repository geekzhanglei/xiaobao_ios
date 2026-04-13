import AVFoundation
import UIKit

class VideoThumbnailGenerator {
    static func generateThumbnail(from videoURL: URL, at time: CMTime = CMTime(seconds: 0, preferredTimescale: 1)) -> URL? {
        let asset = AVAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true

        do {
            let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            let image = UIImage(cgImage: cgImage)

            // Save thumbnail to temp directory
            let filename = UUID().uuidString + "_thumb.jpg"
            let thumbnailURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

            if let data = image.jpegData(compressionQuality: 0.8) {
                try data.write(to: thumbnailURL)
                return thumbnailURL
            }
        } catch {
            print("Error generating thumbnail: \(error)")
        }
        return nil
    }
}
