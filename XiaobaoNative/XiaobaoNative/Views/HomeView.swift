import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: AppStore
    @State private var showParentGate = false
    @State private var showParentView = false
    @State private var showColorPicker = false
    @State private var tapCount = 0
    @State private var lastTapTime = Date()
    @State private var currentThemeColor: String = "#121212"
    @State private var selectedPlayerItems: [ContentItem]?
    @State private var selectedPlayerIndex: Int = 0

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: currentThemeColor)
                    .ignoresSafeArea()

                if store.learningState.locked {
                    LockOverlay(onUnlock: {
                        showParentView = true
                    })
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            ForEach(store.categories, id: \.self) { category in
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(category)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding(.horizontal)

                                    let categoryItems = store.content.filter { $0.category == category }
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 15) {
                                            ForEach(Array(categoryItems.enumerated()), id: \.element.id) { index, item in
                                                Button(action: {
                                                    selectedPlayerItems = categoryItems
                                                    selectedPlayerIndex = index
                                                }) {
                                                    ContentCard(item: item)
                                                        .frame(width: 150)
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }

                if showParentGate {
                    ParentGate(onSuccess: {
                        showParentGate = false
                        showParentView = true
                    }) {
                        showParentGate = false
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("我的书架")
                        .foregroundColor(.white)
                        .onTapGesture {
                            let now = Date()
                            if now.timeIntervalSince(lastTapTime) < 0.5 {
                                tapCount += 1
                                if tapCount >= 4 {
                                    tapCount = 0
                                    showParentView = true
                                }
                            } else {
                                tapCount = 1
                            }
                            lastTapTime = now
                        }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showColorPicker = true
                    }) {
                        Image(systemName: "paintpalette.fill")
                            .foregroundColor(.white)
                    }
                }
            }
            .fullScreenCover(isPresented: Binding(
                get: { selectedPlayerItems != nil },
                set: { if !$0 { selectedPlayerItems = nil } }
            )) {
                if let items = selectedPlayerItems {
                    PlayerView(items: items, initialIndex: selectedPlayerIndex)
                }
            }
            .sheet(isPresented: $showColorPicker) {
                ColorPickerView(isPresented: $showColorPicker, currentColor: currentThemeColor) { color in
                    currentThemeColor = color
                    store.updateThemeColor(color)
                }
            }
            .sheet(isPresented: $showParentView) {
                ParentView()
            }
        }
    }
}

struct ColorPickerView: View {
    @Binding var isPresented: Bool
    let currentColor: String
    let onColorSelected: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    private let colors: [(name: String, hex: String)] = [
        ("白色", "#FFFFFF"),
        ("浅灰", "#F3F4F6"),
        ("浅蓝", "#E0F2FE"),
        ("浅绿", "#DCFCE7"),
        ("浅粉", "#FCE7F3"),
        ("蓝色", "#1E3A8A"),
        ("绿色", "#166534"),
        ("紫色", "#7C3AED"),
        ("粉色", "#DB2777"),
        ("橙色", "#EA580C"),
        ("黑色", "#121212")
    ]

    var body: some View {
        NavigationView {
            List(colors, id: \.hex) { color in
                HStack {
                    Color(hex: color.hex)
                        .frame(width: 40, height: 40)
                        .cornerRadius(8)
                    Text(color.name)
                    Spacer()
                    if currentColor == color.hex {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    onColorSelected(color.hex)
                    dismiss()
                    isPresented = false
                }
            }
            .navigationTitle("选择主题颜色")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        dismiss()
                        isPresented = false
                    }
                }
            }
        }
    }
}
