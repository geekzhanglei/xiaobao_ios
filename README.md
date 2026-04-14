# 小宝学习助手 (iOS Native)

这是一个为儿童设计的学习管理应用，采用纯 Swift 与 SwiftUI 构建。支持家长添加视频、图片内容，并提供精确的学习时长控制功能。

> [!NOTE]
> 项目已从 React Native/Expo 环境完全迁移至原生 Swift 实现，以获得更快的构建速度、更小的体积以及更优的运行性能。

## 🚀 快速开始

本项目需要使用 **Xcode** 进行构建与运行。

1. **克隆项目**:
   ```bash
   git clone https://github.com/geekzhanglei/xiaobao_ios.git
   ```

2. **打开项目**:
   - 进入 `XiaobaoNative` 目录。
   - 双击 `XiaobaoNative.xcodeproj` 用 Xcode 打开。

3. **配置依赖 (SQLite.swift)**:
   - 在 Xcode 中，选择 **File > Add Package Dependencies...**。
   - 输入 URL: `https://github.com/stephencelis/SQLite.swift.git`。
   - 版本选择 `0.14.1` 或更高。
   - 在 `Frameworks, Libraries, and Embedded Content` 中确保已添加 `SQLite`。

4. **运行**:
   - 选择一个模拟器（推荐 iOS 17.0+）。
   - 按下 `Cmd + R` 开始构建并运行。

## 🔐 家长端入口 (重要操作)

为了防止儿童误操作进入管理页面，应用设计了隐藏入口：

- **正常进入**: 在首页点击 **“我的书架”** 文字 **1 秒内连续点击 4 次**。
- **锁定时进入**: 当应用因时长限制被锁定时，连续点击屏幕中央的 **“锁”图标 5 次**。

### 管理功能:
- **时长管理**: 查看已用时长、调节总限时（单位：分钟/秒）、重置时长。
- **分类管理**: 自由添加分类、长按分类标签进行 **重命名** 或 **删除**。
- **内容上传**: 支持从 **相册(图片/视频)** 或 **文件系统(视频)** 导入资源。

## 🛠️ 技术栈

- **UI 框架**: SwiftUI (iOS 15.0+)
- **数据库**: [SQLite.swift](https://github.com/stephencelis/SQLite.swift)
- **状态管理**: `@Observable` (适配 iOS 17+) / `ObservableObject`
- **多媒体**: AVFoundation, AVKit, PHPicker
- **存储**: 本地 Documents 目录 (持久化存储媒体索引与数据库)

## 📁 项目结构

```text
XiaobaoNative/
├── XiaobaoNative/
│   ├── Models/         # 数据模型 (ContentItem, LearningState)
│   ├── Store/          # 状态管理 (AppStore)
│   ├── Database/       # 数据库操作 (DatabaseManager)
│   ├── Views/          # 页面视图 (HomeView, PlayerView, ParentView)
│   ├── Components/     # UI 组件 (ContentCard, ParentGate, Pickers)
│   └── Utils/          # 辅助工具 (ThumbnailGenerator, AppStoreKey)
└── XiaobaoNative.xcodeproj
```

## ⚠️ 注意事项

1. **权限说明**: 首次运行上传功能时，请在真机或模拟器上允许 **相册访问** 和 **文件访问** 权限。
2. **数据库**: 数据存储在本地 `kids_learning.db` 中。如果删除应用，数据将随之清除。
3. **视频支持**: 建议在真机上测试视频播放，以获得最佳的解码效果。

---

*本项目由 Antigravity 辅助构建与优化。*
