import Foundation

struct LearningState: Codable, Equatable {
    var usedTime: Int
    var limit: Int
    var locked: Bool
    var lastPlayTime: Int?
    var themeColor: String
    
    init(usedTime: Int = 0, limit: Int = 600, locked: Bool = false, lastPlayTime: Int? = nil, themeColor: String = "#121212") {
        self.usedTime = usedTime
        self.limit = limit
        self.locked = locked
        self.lastPlayTime = lastPlayTime
        self.themeColor = themeColor
    }
}
