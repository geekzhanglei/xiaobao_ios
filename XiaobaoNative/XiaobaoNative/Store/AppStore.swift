import Foundation
import Combine
import SwiftUI

class AppStore: ObservableObject {
    @Published var content: [ContentItem] = []
    @Published var categories: [String] = []
    @Published var learningState: LearningState = LearningState()

    private let db = DatabaseManager.shared
    private let categoryCacheKey = "xiaobao.customCategories"

    init() {
        loadContent()
        loadCategories()
        loadLearningState()
    }

    func loadContent() {
        content = db.getAllContent()
    }

    func loadCategories() {
        let dbCategories = db.getAllCategories()
        let cachedCategories = getCachedCategories()
        let contentCategories = content.map(\.category)

        categories = mergeCategories(dbCategories, cachedCategories, contentCategories)
        print("AppStore: 加载分类完成，共 \(categories.count) 个: \(categories)")
    }

    func loadLearningState() {
        learningState = db.getLearningState()
    }

    func addContent(_ item: ContentItem) {
        db.addContent(item)
        cacheCategory(item.category)
        loadContent()
        loadCategories()
    }

    func deleteContent(id: String) {
        db.deleteContent(id: id)
        loadContent()
    }

    func moveContent(from source: IndexSet, to destination: Int, in category: String) {
        var categoryContent = content.filter { $0.category == category }
        categoryContent.move(fromOffsets: source, toOffset: destination)
        
        // Update sort indices for all items in this category
        for (index, _) in categoryContent.enumerated() {
            categoryContent[index].sortIndex = index
        }
        
        // Update DB
        db.updateContentIndices(items: categoryContent)
        
        // Reload
        loadContent()
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

        let addedCategory = db.addCategory(name: normalizedName) ?? normalizedName
        cacheCategory(addedCategory)
        loadCategories()
        return addedCategory
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
