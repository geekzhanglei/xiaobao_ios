import AVFoundation
import UIKit
import CryptoKit

class VideoThumbnailGenerator {
    private static let cacheKey = "xiaobao.thumbnailCache"
    private static let fileManager = FileManager.default

    static func generateThumbnail(from videoURL: URL, at time: CMTime? = nil) -> URL? {
        // Use a stable identifier that doesn't change when the app container UUID changes
        let videoIdentifier = videoURL.lastPathComponent
        
        if let cachedThumbnailURL = getCachedThumbnailURL(for: videoIdentifier),
           fileManager.fileExists(atPath: cachedThumbnailURL.path) {
            return cachedThumbnailURL
        }

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
            guard let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
                return nil
            }

            let thumbnailsURL = appSupportURL.appendingPathComponent("Thumbnails", isDirectory: true)

            if !fileManager.fileExists(atPath: thumbnailsURL.path) {
                try? fileManager.createDirectory(at: thumbnailsURL, withIntermediateDirectories: true)
            }

            // Use video identifier as filename for cache
            let filename = videoIdentifier.md5() + "_thumb.jpg"
            let thumbnailURL = thumbnailsURL.appendingPathComponent(filename)

            if let data = image.jpegData(compressionQuality: 0.8) {
                try data.write(to: thumbnailURL)
                // Save to cache with the stable identifier
                cacheThumbnailURL(thumbnailURL, for: videoIdentifier)
                return thumbnailURL
            }
        } catch {
            print("Error generating thumbnail: \(error)")
        }
        return nil
    }

    private static func getCachedThumbnailURL(for videoIdentifier: String) -> URL? {
        guard let cache = UserDefaults.standard.string(forKey: cacheKey),
              let cacheDict = try? JSONDecoder().decode([String: String].self, from: cache.data(using: .utf8) ?? Data()),
              let thumbnailPath = cacheDict[videoIdentifier] else {
            return nil
        }
        
        // If it's an absolute path, re-anchor it to the current container
        let url = URL(fileURLWithPath: thumbnailPath)
        let filename = url.lastPathComponent
        guard let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return url
        }
        
        let thumbnailsURL = appSupportURL.appendingPathComponent("Thumbnails", isDirectory: true)
        return thumbnailsURL.appendingPathComponent(filename)
    }

    private static func cacheThumbnailURL(_ thumbnailURL: URL, for videoIdentifier: String) {
        var cacheDict: [String: String] = [:]
        if let cache = UserDefaults.standard.string(forKey: cacheKey),
           let decoded = try? JSONDecoder().decode([String: String].self, from: cache.data(using: .utf8) ?? Data()) {
            cacheDict = decoded
        }
        cacheDict[videoIdentifier] = thumbnailURL.path
        if let encoded = try? JSONEncoder().encode(cacheDict),
           let cacheString = String(data: encoded, encoding: .utf8) {
            UserDefaults.standard.set(cacheString, forKey: cacheKey)
        }
    }
}

extension String {
    func md5() -> String {
        guard let data = self.data(using: .utf8) else { return "" }
        let hash = Insecure.MD5.hash(data: data)
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}
