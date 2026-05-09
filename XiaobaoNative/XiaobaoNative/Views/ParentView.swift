import SwiftUI

struct ParentView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var showImagePicker = false
    @State private var showVideoPicker = false
    @State private var showDocumentPicker = false
    @State private var newCategoryName = ""
    @State private var selectedCategoryForRename: String?
    @State private var renameTo = ""
    @State private var showEditAlert = false
    @State private var showAlert = false
    @State private var showDeleteAllAlert = false
    @State private var alertMessage = ""
    @State private var isProcessing = false
    @AppStorage("xiaobao.selectedCategory") private var selectedCategory: String = ""
    /// The category that was active when a picker was opened – avoids
    /// stale-closure issues with @AppStorage inside .sheet callbacks.
    @State private var categoryForPicker: String = ""
    private let selectedCategoryKey = "xiaobao.selectedCategory"

    private var contentByCategory: [String: [ContentItem]] {
        store.contentByCategory
    }

    private var trimmedCategoryName: String {
        newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func syncSelectedCategory(with categories: [String]) {
        if !selectedCategory.isEmpty && !categories.contains(selectedCategory) {
            // If the selected category was deleted, clear selection
            selectedCategory = ""
        }
    }

    private func handleAddCategory() {
        if store.categories.contains(trimmedCategoryName) {
            alertMessage = "分类已存在"
            showAlert = true
            selectedCategory = trimmedCategoryName
            return
        }

        guard let addedCategory = store.addCategory(name: trimmedCategoryName) else {
            alertMessage = "添加分类失败，请重试"
            showAlert = true
            return
        }

        selectedCategory = addedCategory
        newCategoryName = ""
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    var body: some View {
        let contentGrouped = contentByCategory
        NavigationView {
            List {
                Section("学习时长") {
                    HStack {
                        Text("已用时长")
                        Spacer()
                        Text("\(store.learningState.usedTime / 60)分\(store.learningState.usedTime % 60)秒")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("总限时")
                        Spacer()
                        Text("\(store.learningState.limit / 60)分\(store.learningState.limit % 60)秒")
                            .foregroundColor(.secondary)
                    }

                    HStack(spacing: 8) {
                        Button("+1m") {
                            var state = store.learningState
                            state.limit += 60
                            store.updateLearningState(state)
                        }
                        .font(.body)
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)

                        Button("-1m") {
                            var state = store.learningState
                            state.limit = max(60, state.limit - 60)
                            store.updateLearningState(state)
                        }
                        .font(.body)
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)

                        Button("+10s") {
                            var state = store.learningState
                            state.limit += 10
                            store.updateLearningState(state)
                        }
                        .font(.body)
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)

                        Button("-10s") {
                            var state = store.learningState
                            state.limit = max(10, state.limit - 10)
                            store.updateLearningState(state)
                        }
                        .font(.body)
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)

                        Button("重置") {
                            store.resetUsedTime()
                        }
                        .font(.body)
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                    }
                }

                Section("分类管理") {
                    HStack {
                        TextField("新分类名称", text: $newCategoryName)
                            .onSubmit {
                                if !trimmedCategoryName.isEmpty {
                                    handleAddCategory()
                                }
                            }
                        Button("添加") {
                            if !trimmedCategoryName.isEmpty {
                                handleAddCategory()
                            }
                        }
                        .disabled(trimmedCategoryName.isEmpty)
                    }

                    ForEach(store.categories, id: \.self) { category in
                        HStack {
                            Label(category, systemImage: "folder")
                                .foregroundColor(selectedCategory == category ? .blue : .primary)
                            Spacer()
                            if selectedCategory == category {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedCategory = category
                        }
                        .contextMenu {
                            Button {
                                selectedCategoryForRename = category
                                renameTo = category
                                showEditAlert = true
                            } label: {
                                Label("重命名", systemImage: "pencil")
                            }

                            if (contentByCategory[category]?.isEmpty ?? true) {
                                Button(role: .destructive) {
                                    store.deleteCategory(name: category)
                                    if selectedCategory == category {
                                        selectedCategory = ""
                                    }
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .onMove(perform: store.moveCategory)
                }

                Section("添加内容 → \(selectedCategory.isEmpty ? (store.categories.first ?? "默认") : selectedCategory)") {
                    Button("选择图片") {
                        if store.categories.isEmpty {
                            alertMessage = "请先创建分类"
                            showAlert = true
                        } else {
                            categoryForPicker = selectedCategory.isEmpty ? (store.categories.first ?? "默认") : selectedCategory
                            showImagePicker = true
                        }
                    }
                    Button("选择视频（相册）") {
                        if store.categories.isEmpty {
                            alertMessage = "请先创建分类"
                            showAlert = true
                        } else {
                            categoryForPicker = selectedCategory.isEmpty ? (store.categories.first ?? "默认") : selectedCategory
                            showVideoPicker = true
                        }
                    }
                    Button("选择视频（文件）") {
                        if store.categories.isEmpty {
                            alertMessage = "请先创建分类"
                            showAlert = true
                        } else {
                            categoryForPicker = selectedCategory.isEmpty ? (store.categories.first ?? "默认") : selectedCategory
                            showDocumentPicker = true
                        }
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showDeleteAllAlert = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("一键清空所有已添加资源")
                                .fontWeight(.bold)
                            Spacer()
                        }
                    }
                } header: {
                    Text("数据重置")
                }

                ForEach(store.categories, id: \.self) { category in
                    Section(header: Text("内容 - \(category)")) {
                        let items = contentGrouped[category] ?? []
                        if items.isEmpty {
                            Text("暂无内容")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(items, id: \.id) { item in
                                HStack(spacing: 12) {
                                    let thumbnailURL = item.validCoverFileURL ?? (item.type == .image ? item.validFileURL : nil)
                                    if let thumbnailURL = thumbnailURL {
                                        LocalImageView(url: thumbnailURL, targetSize: CGSize(width: 50, height: 50), contentMode: .fill) {
                                            ProgressView()
                                                .frame(width: 50, height: 50)
                                        }
                                        .frame(width: 50, height: 50)
                                        .cornerRadius(8)
                                    } else {
                                        Image(systemName: item.type == .video ? "video" : "photo")
                                            .frame(width: 50, height: 50).background(Color.gray.opacity(0.3)).cornerRadius(8)
                                    }

                                    VStack(alignment: .leading) {
                                        Text(item.title ?? "无标题").font(.subheadline)
                                        Text(item.type.rawValue).font(.caption).foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Button(role: .destructive) {
                                        store.deleteContent(id: item.id)
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                    .buttonStyle(.borderless)
                                }
                            }
                            .onMove { from, to in
                                store.moveContent(from: from, to: to, in: category)
                            }
                        }
                    }
                }
            }
            .navigationTitle("家长管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showImagePicker) {
            let targetCategory = categoryForPicker
            ImagePicker { files in
                if files.isEmpty { return }
                isProcessing = true
                let items = files.map { file in
                    ContentItem(
                        id: file.id,
                        type: .image,
                        title: file.title,
                        uri: MediaStorage.relativePath(for: file.url),
                        category: targetCategory
                    )
                }
                store.addContents(items) {
                    isProcessing = false
                }
            }
        }
        .sheet(isPresented: $showVideoPicker) {
            let targetCategory = categoryForPicker
            VideoPicker { files in
                if files.isEmpty { return }
                isProcessing = true
                DispatchQueue.global(qos: .userInitiated).async {
                    let items = files.map { file in
                        let thumbnailURL = VideoThumbnailGenerator.generateThumbnail(from: file.url, contentID: file.id)
                        return ContentItem(
                            id: file.id,
                            type: .video,
                            title: file.title,
                            cover: thumbnailURL.map { MediaStorage.relativePath(for: $0) },
                            uri: MediaStorage.relativePath(for: file.url),
                            category: targetCategory
                        )
                    }
                    DispatchQueue.main.async {
                        store.addContents(items) {
                            isProcessing = false
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showDocumentPicker) {
            let targetCategory = categoryForPicker
            DocumentPicker { files in
                if files.isEmpty { return }
                isProcessing = true
                DispatchQueue.global(qos: .userInitiated).async {
                    let items = files.map { file in
                        let thumbnailURL = VideoThumbnailGenerator.generateThumbnail(from: file.url, contentID: file.id)
                        return ContentItem(
                            id: file.id,
                            type: .video,
                            title: file.title,
                            cover: thumbnailURL.map { MediaStorage.relativePath(for: $0) },
                            uri: MediaStorage.relativePath(for: file.url),
                            category: targetCategory
                        )
                    }
                    DispatchQueue.main.async {
                        store.addContents(items) {
                            isProcessing = false
                        }
                    }
                }
            }
        }
        .alert("编辑分类", isPresented: $showEditAlert) {
            TextField("新名称", text: $renameTo)
            Button("取消", role: .cancel) {
                selectedCategoryForRename = nil
                renameTo = ""
            }
            Button("重命名") {
                if let oldName = selectedCategoryForRename {
                    let trimmedNewName = renameTo.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmedNewName.isEmpty else {
                        alertMessage = "分类名称不能为空"
                        showAlert = true
                        selectedCategoryForRename = nil
                        renameTo = ""
                        return
                    }
                    let renamedCategory = store.renameCategory(oldName: oldName, newName: trimmedNewName)
                    if selectedCategory == oldName {
                        selectedCategory = renamedCategory ?? ""
                    }
                    selectedCategoryForRename = nil
                    renameTo = ""
                }
            }
        } message: {
            if let categoryName = selectedCategoryForRename {
                Text("编辑分类: \(categoryName)")
            } else {
                Text("编辑分类")
            }
        }
        .alert("提示", isPresented: $showAlert) {
            Button("确定") {}
        } message: {
            Text(alertMessage)
        }
        .alert("确定删除所有数据吗？", isPresented: $showDeleteAllAlert) {
            Button("取消", role: .cancel) {}
            Button("确认删除", role: .destructive) {
                store.deleteAllData()
            }
        } message: {
            Text("此操作将永久删除所有已添加的内容，无法撤销。")
        }
        .onAppear {
            syncSelectedCategory(with: store.categories)
        }
        .overlay {
            if isProcessing {
                ZStack {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    VStack(spacing: 15) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("正在处理资源...")
                            .foregroundColor(.white)
                            .font(.headline)
                    }
                    .padding(30)
                    .background(Color.secondary.opacity(0.8))
                    .cornerRadius(15)
                }
            }
        }
        .onChange(of: store.categories) { categories in
            syncSelectedCategory(with: categories)
        }
    }
}
