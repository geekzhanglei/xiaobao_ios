import AVFoundation
import UIKit

nonisolated class VideoThumbnailGenerator {
    private static let fileManager = FileManager.default

    static func generateThumbnail(from videoURL: URL, contentID: String, at time: CMTime? = nil) -> URL? {
        let thumbnailURL = MediaStorage.thumbnailURL(for: contentID)

        if fileManager.fileExists(atPath: thumbnailURL.path) {
            return thumbnailURL
        }

        let asset = AVAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = CGSize(width: 480, height: 480)
        imageGenerator.requestedTimeToleranceBefore = .zero
        imageGenerator.requestedTimeToleranceAfter = .positiveInfinity

        let actualTime: CMTime
        if let time = time {
            actualTime = time
        } else {
            let duration = asset.duration
            let durationSeconds = CMTimeGetSeconds(duration)
            if durationSeconds > 0 && !durationSeconds.isNaN {
                actualTime = CMTime(seconds: min(1.0, max(0.1, durationSeconds * 0.1)), preferredTimescale: 600)
            } else {
                actualTime = CMTime(seconds: 0, preferredTimescale: 1)
            }
        }

        do {
            let cgImage = try imageGenerator.copyCGImage(at: actualTime, actualTime: nil)
            let image = UIImage(cgImage: cgImage)

            try MediaStorage.ensureThumbnailDirectory()
            if let data = image.jpegData(compressionQuality: 0.8) {
                try data.write(to: thumbnailURL, options: .atomic)
                return thumbnailURL
            }
        } catch {
            print("Error generating thumbnail: \(error)")
        }
        return nil
    }

    static func generateThumbnailIfNeeded(for item: ContentItem) -> URL? {
        guard item.type == .video, let videoURL = item.validFileURL else { return nil }
        if let coverURL = item.validCoverFileURL, fileManager.fileExists(atPath: coverURL.path) {
            return coverURL
        }
        return generateThumbnail(from: videoURL, contentID: item.id)
    }
}
