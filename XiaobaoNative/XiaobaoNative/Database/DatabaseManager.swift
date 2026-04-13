import Foundation
import CoreData

class DatabaseManager {
    static let shared = DatabaseManager()

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "XiaobaoNative")
        if let description = container.persistentStoreDescriptions.first {
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true
        }
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Core Data store failed to load: \(error)")
            }
        }
        return container
    }()

    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    private init() {}

    private func normalizedCategoryName(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func save() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Failed to save context: \(error)")
            }
        }
    }

    func getAllContent() -> [ContentItem] {
        let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "ContentEntity")

        do {
            let entities = try context.fetch(request)
            var seenIDs = Set<String>()
            var didRepairIDs = false

            let items = entities.map { entity in
                var id = entity.value(forKey: "id") as? String ?? ""

                // Repair historical records with missing or duplicate ids so single-item deletion
                // only targets the intended record.
                if id.isEmpty || seenIDs.contains(id) {
                    id = UUID().uuidString
                    entity.setValue(id, forKey: "id")
                    didRepairIDs = true
                }

                seenIDs.insert(id)

                return ContentItem(
                    id: id,
                    type: ContentType(rawValue: entity.value(forKey: "type") as? String ?? "video") ?? .video,
                    title: entity.value(forKey: "title") as? String,
                    cover: entity.value(forKey: "cover") as? String,
                    uri: entity.value(forKey: "uri") as? String ?? "",
                    category: entity.value(forKey: "category") as? String ?? "",
                    duration: entity.value(forKey: "duration") as? Int,
                    sortIndex: entity.value(forKey: "sortIndex") as? Int ?? 0
                )
            }
            
            if didRepairIDs {
                save()
            }
            
            // Return items sorted by their index
            return items.sorted(by: { $0.sortIndex < $1.sortIndex })
        } catch {
            print("Error fetching content: \(error)")
            return []
        }
    }

    func addContent(_ item: ContentItem) {
        let contentID = item.id.isEmpty ? UUID().uuidString : item.id
        let entity = NSEntityDescription.insertNewObject(forEntityName: "ContentEntity", into: context)
        entity.setValue(contentID, forKey: "id")
        entity.setValue(item.type.rawValue, forKey: "type")
        entity.setValue(item.title, forKey: "title")
        entity.setValue(item.cover, forKey: "cover")
        entity.setValue(item.uri, forKey: "uri")
        entity.setValue(item.category, forKey: "category")
        entity.setValue(item.duration, forKey: "duration")
        entity.setValue(item.sortIndex, forKey: "sortIndex")
        save()
    }

    func updateContentIndices(items: [ContentItem]) {
        for item in items {
            let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "ContentEntity")
            request.predicate = NSPredicate(format: "id == %@", item.id)
            
            do {
                let entities = try context.fetch(request)
                if let entity = entities.first {
                    entity.setValue(item.sortIndex, forKey: "sortIndex")
                }
            } catch {
                print("Error updating content index for \(item.id): \(error)")
            }
        }
        save()
    }

    func deleteContent(id: String) {
        let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "ContentEntity")
        request.predicate = NSPredicate(format: "id == %@", id)

        do {
            let entities = try context.fetch(request)
            for entity in entities {
                context.delete(entity)
            }
            save()
        } catch {
            print("Error deleting content: \(error)")
        }
    }

    func getAllCategories() -> [String] {
        let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "CategoryEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

        do {
            let entities = try context.fetch(request)
            var seen = Set<String>()
            return entities
                .compactMap { $0.value(forKey: "name") as? String }
                .map(normalizedCategoryName)
                .filter { !$0.isEmpty }
                .filter { seen.insert($0).inserted }
        } catch {
            print("Error fetching categories: \(error)")
            return []
        }
    }

    @discardableResult
    func addCategory(name: String) -> String? {
        let normalizedName = normalizedCategoryName(name)
        guard !normalizedName.isEmpty else {
            print("DatabaseManager: 分类名称为空，跳过保存")
            return nil
        }

        print("DatabaseManager: 添加分类 \(normalizedName)")
        let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "CategoryEntity")

        do {
            let entities = try context.fetch(request)
            let existingName = entities
                .compactMap { $0.value(forKey: "name") as? String }
                .map(normalizedCategoryName)
                .first { $0.localizedCaseInsensitiveCompare(normalizedName) == .orderedSame }

            if let existingName {
                print("DatabaseManager: 分类已存在，跳过")
                return existingName
            }

            let entity = NSEntityDescription.insertNewObject(forEntityName: "CategoryEntity", into: context)
            entity.setValue(normalizedName, forKey: "name")
            save()
            print("DatabaseManager: 分类保存成功")
            return normalizedName
        } catch {
            print("Error checking category: \(error)")
            return nil
        }
    }

    @discardableResult
    func renameCategory(oldName: String, newName: String) -> String? {
        let normalizedOldName = normalizedCategoryName(oldName)
        let normalizedNewName = normalizedCategoryName(newName)

        guard !normalizedOldName.isEmpty, !normalizedNewName.isEmpty else {
            print("DatabaseManager: 重命名分类失败，名称为空")
            return nil
        }

        if normalizedOldName.localizedCaseInsensitiveCompare(normalizedNewName) == .orderedSame {
            return normalizedNewName
        }

        let categoryRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "CategoryEntity")
        let contentRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "ContentEntity")

        do {
            let categoryEntities = try context.fetch(categoryRequest)
            let matchedCategoryEntities = categoryEntities.filter {
                normalizedCategoryName($0.value(forKey: "name") as? String ?? "") == normalizedOldName
            }

            guard !matchedCategoryEntities.isEmpty else {
                print("DatabaseManager: 未找到要重命名的分类 \(normalizedOldName)")
                return nil
            }

            // Check if new name already exists (excluding the old name)
            let hasTargetCategory = categoryEntities.contains {
                let currentName = normalizedCategoryName($0.value(forKey: "name") as? String ?? "")
                return currentName == normalizedNewName && currentName != normalizedOldName
            }

            if hasTargetCategory {
                // If target category exists, merge content into it and delete old category
                let contentEntities = try context.fetch(contentRequest)
                for entity in contentEntities {
                    let currentCategory = normalizedCategoryName(entity.value(forKey: "category") as? String ?? "")
                    if currentCategory == normalizedOldName {
                        entity.setValue(normalizedNewName, forKey: "category")
                    }
                }
                for entity in matchedCategoryEntities {
                    context.delete(entity)
                }
            } else {
                // Otherwise, rename the existing category
                for entity in matchedCategoryEntities {
                    entity.setValue(normalizedNewName, forKey: "name")
                }

                // Update all content items with the old category to use the new category name
                let contentEntities = try context.fetch(contentRequest)
                for entity in contentEntities {
                    let currentCategory = normalizedCategoryName(entity.value(forKey: "category") as? String ?? "")
                    if currentCategory == normalizedOldName {
                        entity.setValue(normalizedNewName, forKey: "category")
                    }
                }
            }

            save()
            return normalizedNewName
        } catch {
            print("Error renaming category: \(error)")
            return nil
        }
    }

    func deleteCategory(name: String) {
        let normalizedName = normalizedCategoryName(name)
        guard !normalizedName.isEmpty else { return }

        let categoryRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "CategoryEntity")
        let contentRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "ContentEntity")

        do {
            // Delete category entities
            let categoryEntities = try context.fetch(categoryRequest)
            for entity in categoryEntities {
                let currentName = normalizedCategoryName(entity.value(forKey: "name") as? String ?? "")
                if currentName == normalizedName {
                    context.delete(entity)
                }
            }

            // Delete content items in this category
            let contentEntities = try context.fetch(contentRequest)
            for entity in contentEntities {
                let currentCategory = normalizedCategoryName(entity.value(forKey: "category") as? String ?? "")
                if currentCategory == normalizedName {
                    context.delete(entity)
                }
            }

            save()
        } catch {
            print("Error deleting category: \(error)")
        }
    }

    func getLearningState() -> LearningState {
        let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "LearningStateEntity")
        request.predicate = NSPredicate(format: "id == 1")

        do {
            let entities = try context.fetch(request)
            if let entity = entities.first {
                return LearningState(
                    usedTime: entity.value(forKey: "usedTime") as? Int ?? 0,
                    limit: entity.value(forKey: "limitTime") as? Int ?? 600,
                    locked: entity.value(forKey: "locked") as? Bool ?? false,
                    lastPlayTime: entity.value(forKey: "lastPlayTime") as? Int,
                    themeColor: entity.value(forKey: "themeColor") as? String ?? "#121212"
                )
            } else {
                let entity = NSEntityDescription.insertNewObject(forEntityName: "LearningStateEntity", into: context)
                entity.setValue(1, forKey: "id")
                entity.setValue(0, forKey: "usedTime")
                entity.setValue(600, forKey: "limitTime")
                entity.setValue(false, forKey: "locked")
                entity.setValue("#121212", forKey: "themeColor")
                save()
                return LearningState()
            }
        } catch {
            print("Error fetching learning state: \(error)")
            return LearningState()
        }
    }

    func updateLearningState(_ state: LearningState) {
        let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "LearningStateEntity")
        request.predicate = NSPredicate(format: "id == 1")

        do {
            let entities = try context.fetch(request)
            let entity = entities.first ?? NSEntityDescription.insertNewObject(forEntityName: "LearningStateEntity", into: context)

            entity.setValue(1, forKey: "id")
            entity.setValue(state.usedTime, forKey: "usedTime")
            entity.setValue(state.limit, forKey: "limitTime")
            entity.setValue(state.locked, forKey: "locked")
            entity.setValue(state.lastPlayTime, forKey: "lastPlayTime")
            entity.setValue(state.themeColor, forKey: "themeColor")

            save()
        } catch {
            print("Error updating learning state: \(error)")
        }
    }
}
