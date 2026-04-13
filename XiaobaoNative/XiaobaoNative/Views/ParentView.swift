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
    @State private var alertMessage = ""
    @AppStorage("xiaobao.selectedCategory") private var selectedCategory: String = ""
    private let selectedCategoryKey = "xiaobao.selectedCategory"

    private var contentByCategory: [String: [ContentItem]] {
        Dictionary(grouping: store.content) { $0.category }
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
                    .onMove(perform: store.moveCategory)
                }

                Section("添加内容") {
                    Button("选择图片") {
                        if store.categories.isEmpty {
                            alertMessage = "请先创建分类"
                            showAlert = true
                        } else {
                            showImagePicker = true
                        }
                    }
                    Button("选择视频（相册）") {
                        if store.categories.isEmpty {
                            alertMessage = "请先创建分类"
                            showAlert = true
                        } else {
                            showVideoPicker = true
                        }
                    }
                    Button("选择视频（文件）") {
                        if store.categories.isEmpty {
                            alertMessage = "请先创建分类"
                            showAlert = true
                        } else {
                            showDocumentPicker = true
                        }
                    }
                }

                Section("内容列表") {
                    ForEach(store.categories, id: \.self) { category in
                        Section(header: Text(category)) {
                            let items = contentByCategory[category] ?? []
                            if items.isEmpty {
                                Text("暂无内容")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                ForEach(items, id: \.id) { item in
                                    HStack(spacing: 12) {
                                        let thumbnailURL = item.cover ?? (item.type == .image ? item.uri : nil)
                                        if let thumbnailURL = thumbnailURL {
                                            AsyncImage(url: URL(string: thumbnailURL)) { phase in
                                                switch phase {
                                                case .empty:
                                                    ProgressView()
                                                        .frame(width: 50, height: 50)
                                                case .success(let image):
                                                    image.resizable().aspectRatio(contentMode: .fill)
                                                        .frame(width: 50, height: 50).cornerRadius(8)
                                                case .failure:
                                                    Image(systemName: "photo").frame(width: 50, height: 50).background(Color.gray.opacity(0.3)).cornerRadius(8)
                                                @unknown default: EmptyView()
                                                }
                                            }
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
            .sheet(isPresented: $showImagePicker) {
                ImagePicker { urls in
                    for url in urls {
                        let category = selectedCategory.isEmpty ? (store.categories.first ?? "默认") : selectedCategory
                        let item = ContentItem(
                            type: .image,
                            title: "图片",
                            uri: url.absoluteString,
                            category: category
                        )
                        store.addContent(item)
                    }
                }
            }
            .sheet(isPresented: $showVideoPicker) {
                VideoPicker { urls in
                    for url in urls {
                        let category = selectedCategory.isEmpty ? (store.categories.first ?? "默认") : selectedCategory
                        // Generate thumbnail for video
                        let thumbnailURL = VideoThumbnailGenerator.generateThumbnail(from: url)
                        let item = ContentItem(
                            type: .video,
                            title: "视频",
                            cover: thumbnailURL?.absoluteString,
                            uri: url.absoluteString,
                            category: category
                        )
                        store.addContent(item)
                    }
                }
            }
            .sheet(isPresented: $showDocumentPicker) {
                DocumentPicker { urls in
                    for url in urls {
                        let category = selectedCategory.isEmpty ? (store.categories.first ?? "默认") : selectedCategory
                        // Generate thumbnail for video
                        let thumbnailURL = VideoThumbnailGenerator.generateThumbnail(from: url)
                        let item = ContentItem(
                            type: .video,
                            title: url.lastPathComponent,
                            cover: thumbnailURL?.absoluteString,
                            uri: url.absoluteString,
                            category: category
                        )
                        store.addContent(item)
                    }
                }
            }
            .alert("编辑分类", isPresented: $showEditAlert) {
                TextField("新名称", text: $renameTo)
                Button("取消", role: .cancel) {
                    selectedCategoryForRename = nil
                    renameTo = ""
                }
                Button("删除", role: .destructive) {
                    if let oldName = selectedCategoryForRename {
                        store.deleteCategory(name: oldName)
                        if selectedCategory == oldName {
                            selectedCategory = ""
                        }
                        selectedCategoryForRename = nil
                        renameTo = ""
                    }
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
            .onAppear {
                syncSelectedCategory(with: store.categories)
            }
            .onChange(of: store.categories) { categories in
                syncSelectedCategory(with: categories)
            }
        }
    }
}
