import Foundation
import Combine
import SwiftUI

@MainActor
class AppStore: ObservableObject {
    @Published var content: [ContentItem] = []
    @Published private(set) var contentByCategory: [String: [ContentItem]] = [:]
    @Published var categories: [String] = []
    @Published var learningState: LearningState = LearningState()

    private let db = DatabaseManager.shared
    private let categoryCacheKey = "xiaobao.customCategories"
    private var thumbnailRepairIDs = Set<String>()

    init() {
        checkMidnightReset()
        ensureDefaultCategoryExists()
        loadContent()
        loadCategories()
        loadLearningState()
    }

    private func ensureDefaultCategoryExists() {
        // Ensure default category exists in database
        if db.addCategory(name: "默认") == nil {
            // Category already exists or failed to add, ensure it's in cache
            cacheCategory("默认")
        } else {
            cacheCategory("默认")
        }
    }

    private func checkMidnightReset() {
        let lastResetKey = "xiaobao.lastResetDate"
        let now = Date()
        let calendar = Calendar.current

        if let lastReset = UserDefaults.standard.object(forKey: lastResetKey) as? Date {
            if !calendar.isDate(lastReset, inSameDayAs: now) {
                resetUsedTime()
                UserDefaults.standard.set(now, forKey: lastResetKey)
            }
        } else {
            UserDefaults.standard.set(now, forKey: lastResetKey)
        }
    }

    func loadContent() {
        content = db.getAllContent()
        rebuildContentByCategory()
        repairMissingThumbnailsIfNeeded()
    }

    func loadCategories() {
        let dbCategories = db.getAllCategories()
        let cachedCategories = getCachedCategories()
        let contentCategories = content.map(\.category)

        // Prioritize cachedCategories to preserve custom ordering
        var merged = mergeCategories(cachedCategories, dbCategories, contentCategories)

        // Ensure '默认' category always exists in the DB and list
        if !merged.contains("默认") {
            db.addCategory(name: "默认")
            merged.insert("默认", at: 0)
            cacheCategory("默认")
        } else {
            // If '默认' exists but is not at first position, move it to first
            if let index = merged.firstIndex(of: "默认"), index != 0 {
                merged.remove(at: index)
                merged.insert("默认", at: 0)
                saveCachedCategories(merged)
            }
        }

        categories = merged
        print("AppStore: 加载分类完成，共 \(categories.count) 个: \(categories)")
    }

    func loadLearningState() {
        learningState = db.getLearningState()
    }

    func addContent(_ item: ContentItem) {
        addContents([item])
    }

    func addContents(_ items: [ContentItem], completion: (() -> Void)? = nil) {
        guard !items.isEmpty else {
            completion?()
            return
        }
        
        print("AppStore: 批量添加 \(items.count) 个内容")
        
        var nextSortIndexByCategory = Dictionary(grouping: content, by: \.category).mapValues { items in
            (items.map(\.sortIndex).max() ?? -1) + 1
        }

        // Normalize paths to relative format before saving to DB for stability
        let normalizedItems = items.map { item -> ContentItem in
            let sortIndex = nextSortIndexByCategory[item.category] ?? 0
            nextSortIndexByCategory[item.category] = sortIndex + 1

            return ContentItem(
                id: item.id,
                type: item.type,
                title: item.title,
                cover: toRelativePath(item.cover),
                uri: toRelativePath(item.uri) ?? item.uri,
                category: item.category,
                duration: item.duration,
                sortIndex: sortIndex
            )
        }

        // Cache categories first (fast)
        for item in normalizedItems {
            cacheCategory(item.category)
        }

        db.addContentsBatch(normalizedItems) { [weak self] in
            guard let self = self else { return }
            self.loadContent()
            
            // Only reload categories if new categories were added
            let newCategories = Set(normalizedItems.map(\.category))
            let hasNewCategories = !newCategories.isSubset(of: Set(self.categories))
            if hasNewCategories {
                self.loadCategories()
            }
            
            completion?()
        }
    }

    func deleteContent(id: String) {
        if let item = content.first(where: { $0.id == id }) {
            MediaStorage.deleteFiles(for: item)
        }
        db.deleteContent(id: id)
        loadContent()
    }

    func deleteAllData() {
        content.forEach { MediaStorage.deleteFiles(for: $0) }
        db.deleteAllContent()
        MediaStorage.clearManagedMedia()
        thumbnailRepairIDs.removeAll()
        loadContent()
    }

    func moveContent(from source: IndexSet, to destination: Int, in category: String) {
        var categoryContent = content.filter { $0.category == category }
        categoryContent.move(fromOffsets: source, toOffset: destination)

        // Update sort indices for all items in this category
        for (index, _) in categoryContent.enumerated() {
            categoryContent[index].sortIndex = index
        }

        db.updateContentIndices(items: categoryContent) { [weak self] in
            self?.loadContent()
        }
    }

    func moveCategory(from source: IndexSet, to destination: Int) {
        categories.move(fromOffsets: source, toOffset: destination)
        saveCachedCategories(categories)
    }

    @discardableResult
    func addCategory(name: String) -> String? {
        let normalizedName = normalizedCategoryName(name)
        guard !normalizedName.isEmpty else {
            return nil
        }

        if let addedCategory = db.addCategory(name: normalizedName) {
            cacheCategory(addedCategory)
            
            // Optimization: if it's already in our categories list, don't trigger a full reload
            if !categories.contains(addedCategory) {
                loadCategories()
            }
            return addedCategory
        }
        return nil
    }

    @discardableResult
    func renameCategory(oldName: String, newName: String) -> String? {
        let normalizedOldName = normalizedCategoryName(oldName)
        let normalizedNewName = normalizedCategoryName(newName)
        guard !normalizedOldName.isEmpty, !normalizedNewName.isEmpty else {
            return nil
        }

        let renamedCategory = db.renameCategory(oldName: normalizedOldName, newName: normalizedNewName) ?? normalizedNewName
        renameCachedCategory(oldName: normalizedOldName, newName: renamedCategory)

        // Critical: reload content first so the categories derived from content reflect the change
        loadContent()
        loadCategories()

        return renamedCategory
    }

    func deleteCategory(name: String) {
        let normalizedName = normalizedCategoryName(name)
        guard !normalizedName.isEmpty else { return }

        db.deleteCategory(name: normalizedName)
        removeCachedCategory(normalizedName)
        loadCategories()
    }

    func updateLearningState(_ state: LearningState) {
        learningState = state
        db.updateLearningState(state)
    }

    func incrementUsedTime(seconds: Int) {
        var state = learningState
        state.usedTime += seconds
        if state.usedTime >= state.limit {
            state.locked = true
        }
        updateLearningState(state)
    }

    func resetUsedTime() {
        var state = learningState
        state.usedTime = 0
        state.limit = 600
        state.locked = false
        learningState = state
        db.updateLearningState(state)
    }

    func updateThemeColor(_ color: String) {
        var state = learningState
        state.themeColor = color
        learningState = state
        updateLearningState(learningState)
    }

    private func normalizedCategoryName(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func toRelativePath(_ path: String?) -> String? {
        guard let path = path else { return nil }
        guard path.contains("file://") || path.hasPrefix("/") else { return path }
        
        let url: URL
        if path.hasPrefix("/") {
            url = URL(fileURLWithPath: path)
        } else if let u = URL(string: path) {
            url = u
        } else {
            return path
        }
        
        return MediaStorage.relativePath(for: url)
    }

    private func rebuildContentByCategory() {
        contentByCategory = Dictionary(grouping: content, by: \.category).mapValues { items in
            items.sorted {
                if $0.sortIndex != $1.sortIndex {
                    return $0.sortIndex < $1.sortIndex
                }
                return $0.id < $1.id
            }
        }
    }

    private func repairMissingThumbnailsIfNeeded() {
        let candidates = content.filter { item in
            guard item.type == .video, !thumbnailRepairIDs.contains(item.id), item.validFileURL != nil else {
                return false
            }
            if let coverURL = item.validCoverFileURL, FileManager.default.fileExists(atPath: coverURL.path) {
                return false
            }
            return true
        }

        guard !candidates.isEmpty else { return }
        candidates.forEach { thumbnailRepairIDs.insert($0.id) }

        DispatchQueue.global(qos: .utility).async {
            let repaired = candidates.compactMap { item -> (String, String)? in
                guard let thumbnailURL = VideoThumbnailGenerator.generateThumbnailIfNeeded(for: item) else {
                    return nil
                }
                return (item.id, MediaStorage.relativePath(for: thumbnailURL))
            }

            guard !repaired.isEmpty else { return }
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                for (id, cover) in repaired {
                    self.db.updateContentCover(id: id, cover: cover)
                }
                self.loadContent()
            }
        }
    }

    private func mergeCategories(_ groups: [String]...) -> [String] {
        var deduped: [String] = []
        var seen = Set<String>()

        for group in groups {
            for raw in group {
                let name = normalizedCategoryName(raw)
                guard !name.isEmpty else { continue }
                guard !seen.contains(name) else { continue }

                seen.insert(name)
                deduped.append(name)
            }
        }

        return deduped
    }

    private func getCachedCategories() -> [String] {
        UserDefaults.standard.stringArray(forKey: categoryCacheKey) ?? []
    }

    private func saveCachedCategories(_ categories: [String]) {
        let merged = mergeCategories(categories)
        UserDefaults.standard.set(merged, forKey: categoryCacheKey)
    }

    private func cacheCategory(_ category: String) {
        let merged = mergeCategories(getCachedCategories(), [category])
        UserDefaults.standard.set(merged, forKey: categoryCacheKey)
    }

    private func renameCachedCategory(oldName: String, newName: String) {
        let normalizedOldName = normalizedCategoryName(oldName)
        let normalizedNewName = normalizedCategoryName(newName)
        guard !normalizedOldName.isEmpty, !normalizedNewName.isEmpty else { return }

        let updated = getCachedCategories().map {
            normalizedCategoryName($0) == normalizedOldName ? normalizedNewName : $0
        }
        saveCachedCategories(updated)
    }

    private func removeCachedCategory(_ category: String) {
        let normalizedName = normalizedCategoryName(category)
        guard !normalizedName.isEmpty else { return }

        let updated = getCachedCategories().filter {
            normalizedCategoryName($0) != normalizedName
        }
        saveCachedCategories(updated)
    }
}
