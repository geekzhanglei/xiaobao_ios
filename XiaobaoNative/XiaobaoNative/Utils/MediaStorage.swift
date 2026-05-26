import Foundation

nonisolated struct PickedMediaFile: Sendable {
    let id: String
    let url: URL
    let title: String
}

nonisolated enum MediaStorage {
    enum MediaKind {
        case video
        case image
    }

    private static let fileManager = FileManager.default

    static var mediaRootURL: URL {
        documentsURL.appendingPathComponent("Media", isDirectory: true)
    }

    static var videosURL: URL {
        mediaRootURL.appendingPathComponent("Videos", isDirectory: true)
    }

    static var imagesURL: URL {
        mediaRootURL.appendingPathComponent("Images", isDirectory: true)
    }

    static var thumbnailsURL: URL {
        applicationSupportURL.appendingPathComponent("Thumbnails", isDirectory: true)
    }

    static func storeImportedFile(from sourceURL: URL, kind: MediaKind, contentID: String, preferredFilename: String? = nil) throws -> URL {
        let directory = kind == .video ? videosURL : imagesURL
        try ensureDirectoryExists(directory)

        let fileExtension = storedFileExtension(
            sourceURL: sourceURL,
            preferredFilename: preferredFilename,
            fallback: kind == .video ? "mov" : "jpg"
        )
        let destination = directory.appendingPathComponent(contentID).appendingPathExtension(fileExtension)

        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }
        try fileManager.copyItem(at: sourceURL, to: destination)
        return destination
    }

    static func relativePath(for url: URL) -> String {
        let standardizedURL = url.standardizedFileURL
        let path = standardizedURL.path

        if path.hasPrefix(videosURL.path + "/") {
            return "media-video://\(standardizedURL.lastPathComponent)"
        }
        if path.hasPrefix(imagesURL.path + "/") {
            return "media-image://\(standardizedURL.lastPathComponent)"
        }
        if path.hasPrefix(thumbnailsURL.path + "/") {
            return "thumbnail://\(standardizedURL.lastPathComponent)"
        }
        if path.hasPrefix(documentsURL.path + "/") {
            return "documents://\(standardizedURL.lastPathComponent)"
        }
        if path.hasPrefix(applicationSupportURL.path + "/") {
            let relativePath = path.replacingOccurrences(of: applicationSupportURL.path + "/", with: "")
            return "appsupport://\(relativePath)"
        }
        return url.absoluteString
    }

    static func resolvePath(_ path: String) -> URL? {
        if path.hasPrefix("media-video://") {
            return videosURL.appendingPathComponent(path.replacingOccurrences(of: "media-video://", with: ""))
        }
        if path.hasPrefix("media-image://") {
            return imagesURL.appendingPathComponent(path.replacingOccurrences(of: "media-image://", with: ""))
        }
        if path.hasPrefix("thumbnail://") {
            return thumbnailsURL.appendingPathComponent(path.replacingOccurrences(of: "thumbnail://", with: ""))
        }
        if path.hasPrefix("documents://") {
            return documentsURL.appendingPathComponent(path.replacingOccurrences(of: "documents://", with: ""))
        }
        if path.hasPrefix("appsupport://") {
            return applicationSupportURL.appendingPathComponent(path.replacingOccurrences(of: "appsupport://", with: ""))
        }
        if path.hasPrefix("/") {
            return URL(fileURLWithPath: path)
        }
        if let url = URL(string: path), url.isFileURL {
            return url
        }
        return URL(string: path)
    }

    static func thumbnailURL(for contentID: String) -> URL {
        thumbnailsURL.appendingPathComponent("\(contentID)_thumb.jpg")
    }

    static func thumbnailRelativePath(for contentID: String) -> String {
        relativePath(for: thumbnailURL(for: contentID))
    }

    static func ensureThumbnailDirectory() throws {
        try ensureDirectoryExists(thumbnailsURL)
    }

    static func deleteFiles(for item: ContentItem) {
        deleteManagedFile(at: item.validFileURL)
        if let coverFileURL = item.validCoverFileURL {
            deleteManagedFile(at: coverFileURL)
        }
        deleteManagedFile(at: thumbnailURL(for: item.id))
    }

    static func clearManagedMedia() {
        deleteDirectoryContents(at: mediaRootURL)
        deleteDirectoryContents(at: thumbnailsURL)
    }

    private static var documentsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private static var applicationSupportURL: URL {
        fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    }

    private static func ensureDirectoryExists(_ url: URL) throws {
        if !fileManager.fileExists(atPath: url.path) {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }

    private static func normalizedFileExtension(from filename: String, fallback: String) -> String {
        let ext = URL(fileURLWithPath: filename).pathExtension
        return ext.isEmpty ? fallback : ext.lowercased()
    }

    private static func storedFileExtension(sourceURL: URL, preferredFilename: String?, fallback: String) -> String {
        let sourceExtension = sourceURL.pathExtension
        if !sourceExtension.isEmpty {
            return sourceExtension.lowercased()
        }

        if let preferredFilename {
            return normalizedFileExtension(from: preferredFilename, fallback: fallback)
        }

        return fallback
    }

    private static func deleteManagedFile(at url: URL?) {
        guard let url else { return }
        let path = url.standardizedFileURL.path
        let roots = [mediaRootURL.path, thumbnailsURL.path, documentsURL.path]
        guard roots.contains(where: { path.hasPrefix($0 + "/") }) else { return }
        try? fileManager.removeItem(at: url)
    }

    private static func deleteDirectoryContents(at url: URL) {
        guard fileManager.fileExists(atPath: url.path) else { return }
        if let contents = try? fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil) {
            for child in contents {
                try? fileManager.removeItem(at: child)
            }
        }
    }
}
