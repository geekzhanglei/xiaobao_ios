# 小宝学习助手 (Swift 原生版)

基于 SwiftUI 构建的儿童学习管理应用，纯 Swift 原生实现，构建速度更快。

## 技术栈

- **UI 框架**: SwiftUI
- **数据库**: SQLite.swift
- **状态管理**: @Observable (iOS 17+)
- **视频播放**: AVKit / AVFoundation
- **图片选择**: PHPickerViewController
- **文件选择**: UIDocumentPickerViewController

## 项目结构

```
XiaobaoNative/
├── Sources/XiaobaoNative/
│   ├── Models/              # 数据模型
│   │   ├── ContentItem.swift
│   │   └── LearningState.swift
│   ├── Database/            # 数据库层
│   │   └── DatabaseManager.swift
│   ├── Store/               # 状态管理
│   │   └── AppStore.swift
│   ├── Views/               # SwiftUI 视图
│   │   ├── HomeView.swift
│   │   ├── PlayerView.swift
│   │   └── ParentView.swift
│   ├── Components/          # 可复用组件
│   │   ├── ContentCard.swift
│   │   ├── ParentGate.swift
│   │   ├── LockOverlay.swift
│   │   ├── ImagePicker.swift
│   │   ├── VideoPicker.swift
│   │   └── DocumentPicker.swift
│   ├── Utils/               # 工具类
│   │   ├── AppStoreKey.swift
│   │   └── Color+Hex.swift
│   └── XiaobaoNativeApp.swift
└── Package.swift
```

## 功能特性

### 首页
- 按分类分组展示内容
- 横向滚动浏览
- 主题颜色切换
- 家长门禁入口（连续点击 4 次）

### 播放器
- 视频/图片播放
- 横竖屏自适应
- 时长追踪
- 滑动切换同分类内容

### 家长管理
- 学习时长管理（已用时长、总限时调节）
- 分类管理（新增、重命名、删除）
- 内容上传（相册图片、相册视频、文件视频）
- 所有内容展示与删除

### 家长门禁
- 锁定状态时连续点击锁图标 5 次解锁
- 防止儿童误操作

## 开发说明

### 构建要求

- Xcode 15.0+
- iOS 15.0+
- Swift 5.9+

### 运行项目

1. 打开 `XiaobaoNative/XiaobaoNative.xcodeproj`
2. 在 Xcode 中，选择 File > Add Package Dependencies
3. 输入 URL: `https://github.com/stephencelis/SQLite.swift.git`
4. 选择版本 0.14.0 或更高
5. 点击 Add Package
6. 选择项目 target，在 Build Phases > Link Binary With Libraries 中添加 SQLite
7. 运行项目（Cmd + R）

### 权限配置

在 Info.plist 中添加：

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>需要访问相册来选择图片和视频</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>需要保存图片到相册</string>
<key>NSDocumentsFolderUsageDescription</key>
<string>需要访问文件来选择视频</string>
```

### iPad 全屏配置

为确保应用在 iPad 上全屏显示，项目已配置：

- `LaunchScreen.storyboard` - 启动屏幕
- `INFOPLIST_KEY_UILaunchStoryboardName = "LaunchScreen"` - 指定启动屏幕
- `INFOPLIST_KEY_UIRequiresFullScreen = YES` - 强制全屏显示

这些配置在 `project.pbxproj` 的 Debug 和 Release 构建配置中均已设置。

## 数据迁移

从 React Native 版本迁移数据：

1. 使用旧版本应用导出数据库文件
2. 将 `kids_learning.db` 复制到新应用的 Documents 目录
3. 数据库结构兼容，无需转换

## 与 React Native 版本对比

| 特性 | React Native | Swift 原生 |
|------|-------------|-----------|
| 构建速度 | 慢（需要 Metro bundler） | 快（直接编译） |
| 打包速度 | 慢 | 快 |
| 启动速度 | 较慢 | 快 |
| 包体积 | 较大（包含 RN 框架） | 较小 |
| 开发效率 | 高（热重载） | 中（需要重新编译） |
| 性能 | 中等 | 高 |
| 维护成本 | 低（跨平台） | 高（仅 iOS） |

## 后续优化

- [ ] 视频缩略图生成（AVAssetImageGenerator）
- [ ] 数据迁移工具 UI
- [ ] 更多主题颜色
- [ ] 播放历史记录
- [ ] 学习报告统计
