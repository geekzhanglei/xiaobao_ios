# 小宝学习助手 (iOS Demo)

这是一个基于 Expo 构建的儿童学习管理应用，支持家长添加视频/图片内容，并提供学习时长控制功能。

## � 项目版本

项目提供两个版本：

1. **React Native 版本** (当前目录) - 基于 Expo + React Native，跨平台支持
2. **Swift 原生版本** (`XiaobaoNative/` 目录) - 纯 Swift + SwiftUI，构建速度更快

### Swift 原生版本

为了加快构建和打包速度，项目已迁移至 Swift 原生实现。详细信息请查看 [XiaobaoNative/README.md](./XiaobaoNative/README.md)

**优势**：
- 构建速度提升 3-5 倍
- 打包速度更快
- 启动速度更快
- 包体积更小
- 性能更优

**快速开始**：
```bash
cd XiaobaoNative
open XiaobaoNative.xcodeproj
# 在 Xcode 中添加 SQLite.swift 依赖后运行
```

## �🚀 快速开始

1. **安装依赖**
   ```bash
   pnpm install
   ```

2. **启动项目**
   ```bash
   pnpm de (React Native 版本)v     # 启动项目
   pnpm run ios     # 启动 iOS 模拟器p
   pnpm run android # 启动 Android 模拟器
   ```

## 🔐 家长端入口 (重要)


## 🛠️ 技术栈 (Swift 原生版本)

- **UI 框架**: SwiftUI
- **数据库**: SQLite.swift
- **状态管理**: @Observable (iOS 17+)
- **视频播放**: AVKit / AVFoundation
- **图片选择**: PHPickerViewController
- **文件选择**: UIDocumentPickerViewController
为了防止儿童误操作进入管理页面，应用设计了一个**隐藏入口**：

- **操作方式**: 在首页点击 **“我的书架”** 文字 **1 秒内连续点击 4 次**。
- **锁定状态**: 当应用因时长限制被锁定时，连续点击屏幕中央的 **“锁”图标 5 次** 即可进入家长管理。
- **功能**:
  - **背景选择**: 首页右上角支持儿童自主切换背景颜色（支持持久化保存）。
  - **时长管理**: 精确到秒的已用时长查看、总限时调节（+1min, -1min, +10s, -10s）及重置。
  - **锁定逻辑**: 学习时长耗尽后，退出当前播放内容将触发全局锁定，提示“今天就学习到这里了，不能再看了”。
  - **分类管理**:
    - **新增**: 输入名称后点击绿色加号添加。
    - **重命名**: **长按**分类标签，选择“重命名”并输入新名称，所属内容会自动迁移。
    - **删除**: **长按**分类标签，选择“删除”。
  - **内容上传**: 支持三种上传方式：
    - **相册图片**: 从手机相册选择图片。
    - **相册视频**: 从手机相册选择视频。
    - **文件视频**: 从手机文件系统选择视频。
  - **内容管理**: 所有已上传内容按分类分组展示，支持单个删除。

## 🛠️ 技术栈

- **框架**: Expo (SDK 54) + React Native
- **路由**: Expo Router (文件系统路由)
- **状态管理**: Zustand
- **持久化**: Expo SQLite (本地数据库)
- **UI/图标**: Lucide React Native + Tailwind-like styles

## ⚠️ 常见坑点 & 注意事项

1. **媒体权限**:
   - 家长端添加图片/视频需要相册和文件访问权限。在真机调试时，请确保已在系统设置中授权。
2. **本地数据库 (SQLite)**:
   - 所有的内容索引和学习时长都存储在本地 `kids_learning.db` 中。如果清除应用数据或重新安装，这些数据将会丢失。
3. **缓存问题**:
   - 项目配置了自定义缓存目录 `.expo_cache`。如果遇到奇怪的编译错误，可以尝试删除该目录后重启。
4. **视频支持**:
   - 视频播放依赖 `expo-av`。在某些模拟器上，视频解码可能不稳定，建议优先使用真机或图片进行测试。
5. **锁定逻辑**:
   - 学习时长到达限额后，应用会弹出全屏锁定层。此时只能通过右上角的“家长入口”进入管理后台进行重置。

## 📁 目录结构

- `app/`: 页面路由 (首页、播放页、家长页)
- `src/components/`: 通用 UI 组件
- `src/database/`: SQLite 数据库操作逻辑
- `src/store/`: Zustand 状态管理
- `assets/`: 静态资源 (图标、启动图)

## 🔄 CI/CD 构建

项目使用 GitHub Actions 进行 iOS 自动化构建，工作流位于 `.github/workflows/ios-build.yml`。

### 本地构建命令

```bash
pnpm ios:setup    # 生成原生代码并安装 pods (expo prebuild + pod install)
pnpm ios:clean    # 清理并重新生成原生代码
pnpm ios:build    # 本地构建 Release 版本 (开发调试用)
```

### CI/CD 流程

1. 安装依赖 (pnpm install)
2. 设置 iOS 证书和描述文件
3. 运行 `pnpm ios:setup` 生成原生代码
4. 使用 xcodebuild 创建 archive
5. 导出 IPA 文件
6. 上传构建产物

**注意**: CI/CD 使用 xcodebuild 而非 `pnpm ios:build`，因为 `expo run:ios` 不会创建 xcarchive 文件，无法用于导出 IPA。
