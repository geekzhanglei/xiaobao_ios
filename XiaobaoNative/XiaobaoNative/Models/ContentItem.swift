import Foundation

nonisolated enum ContentType: String, Codable, Sendable {
    case video = "video"
    case image = "image"
}

nonisolated struct ContentItem: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let type: ContentType
    let title: String?
    let cover: String?
    let uri: String
    let category: String
    let duration: Int?
    var sortIndex: Int
    
    var validCover: String? {
        guard let cover = cover else { return nil }
        return validCoverFileURL?.absoluteString ?? cover
    }

    var validURI: String {
        return validFileURL?.absoluteString ?? uri
    }

    var validFileURL: URL? {
        MediaStorage.resolvePath(uri)
    }

    var validCoverFileURL: URL? {
        guard let cover = cover else { return nil }
        return MediaStorage.resolvePath(cover)
    }

    private func resolvePath(_ path: String) -> String? {
        if let resolved = MediaStorage.resolvePath(path) {
            return resolved.absoluteString
        }

        // Handle relative path schemes
        if path.hasPrefix("documents://") {
            let filename = path.replacingOccurrences(of: "documents://", with: "")
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            return documentsURL?.appendingPathComponent(filename).absoluteString
        }
        
        if path.hasPrefix("appsupport://") {
            let relativePath = path.replacingOccurrences(of: "appsupport://", with: "")
            let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            return appSupportURL?.appendingPathComponent(relativePath).absoluteString
        }

        // If it's not a local file path, return as is
        guard path.contains("file://") || path.hasPrefix("/") else { return path }
        
        let url: URL
        if path.hasPrefix("/") {
            url = URL(fileURLWithPath: path)
        } else if let u = URL(string: path) {
            url = u
        } else {
            return path
        }
        
        let filename = url.lastPathComponent
        let pathString = url.path
        
        // If it's in Thumbnails folder (Application Support)
        if pathString.contains("/Library/Application Support/") || pathString.contains("/Thumbnails/") {
            let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            // Reconstruct the path relative to Application Support
            // Most thumbnails are in Library/Application Support/Thumbnails/
            return appSupportURL?.appendingPathComponent("Thumbnails").appendingPathComponent(filename).absoluteString
        }
        
        // Default to Documents folder for other local files (videos/images)
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return documentsURL?.appendingPathComponent(filename).absoluteString
    }

    init(id: String = UUID().uuidString, type: ContentType, title: String? = nil, cover: String? = nil, uri: String, category: String, duration: Int? = nil, sortIndex: Int = 0) {
        self.id = id
        self.type = type
        self.title = title
        self.cover = cover
        self.uri = uri
        self.category = category
        self.duration = duration
        self.sortIndex = sortIndex
    }
}
