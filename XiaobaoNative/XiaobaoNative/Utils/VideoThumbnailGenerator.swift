import AVFoundation
import UIKit

class VideoThumbnailGenerator {
    static func generateThumbnail(from videoURL: URL, at time: CMTime? = nil) -> URL? {
        let asset = AVAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true

        let actualTime: CMTime
        if let time = time {
            actualTime = time
        } else {
            // Get random time between 10% and 90% of duration to make covers more diverse
            let duration = asset.duration
            let durationSeconds = CMTimeGetSeconds(duration)
            if durationSeconds > 0 && !durationSeconds.isNaN {
                let randomSeconds = Double.random(in: min(1.0, durationSeconds * 0.1)...max(1.0, durationSeconds * 0.9))
                actualTime = CMTime(seconds: randomSeconds, preferredTimescale: 600)
            } else {
                actualTime = CMTime(seconds: 0, preferredTimescale: 1)
            }
        }

        do {
            let cgImage = try imageGenerator.copyCGImage(at: actualTime, actualTime: nil)
            let image = UIImage(cgImage: cgImage)

            // Save thumbnail to persistent Application Support directory
            let fileManager = FileManager.default
            guard let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
                return nil
            }
            
            let thumbnailsURL = appSupportURL.appendingPathComponent("Thumbnails", isDirectory: true)
            
            if !fileManager.fileExists(atPath: thumbnailsURL.path) {
                try? fileManager.createDirectory(at: thumbnailsURL, withIntermediateDirectories: true)
            }

            let filename = UUID().uuidString + "_thumb.jpg"
            let thumbnailURL = thumbnailsURL.appendingPathComponent(filename)

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
