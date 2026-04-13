import Foundation

enum ContentType: String, Codable {
    case video = "video"
    case image = "image"
}

struct ContentItem: Codable, Identifiable, Equatable {
    let id: String
    let type: ContentType
    let title: String?
    let cover: String?
    let uri: String
    let category: String
    let duration: Int?
    var sortIndex: Int
    
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
