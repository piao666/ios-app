# 📱 应用图标 (App Icon) 创建完整指南

## 1️⃣ 目前的状态

### 已完成
- ✅ `Assets.xcassets/AppIcon.appiconset/Contents.json` 配置完整
- ✅ `AppLogo-1024.png` 源文件已准备
- ✅ 支持所有 iOS 设备尺寸定义

### 待完成
- ⏳ 11 个不同尺寸的 PNG 文件自动生成
- ⏳ 在 CI/CD 流程中自动转换

---

## 2️⃣ 应用图标所需的 11 个尺寸

```
即时通讯和系统显示：
├─ 20x20@2x  (40x40)   -- iPhone 通知角标、设置
├─ 20x20@3x  (60x60)   -- iPhone XS/11 等
├─ 29x29@2x  (58x58)   -- iPhone Home 屏小图 / 设置
├─ 29x29@3x  (87x87)   -- iPhone XS/11 等

主屏幕和多任务：
├─ 40x40@2x  (80x80)   -- iPhone Spotlight 搜索
├─ 40x40@3x  (120x120) -- iPhone 11
├─ 60x60@2x  (120x120) -- iPhone Home 屏
├─ 60x60@3x  (180x180) -- iPhone XS/11/12 等主屏幕

iPad：
├─ 76x76@2x  (152x152) -- iPad Home 屏
├─ 83.5x83.5@2x (167x167) -- iPad Pro

分发：
└─ 1024x1024 (1024x1024) -- App Store
```

---

## 3️⃣ 如何创建应用图标

### 方案 A：使用在线工具（快速简易）
1. 访问：https://appicon.co/ 或 https://www.figma.com/
2. 上传 `AppLogo-1024.png`
3. 一键生成所有 11 个尺寸

### 方案 B：使用 macOS Xcode
1. 在 Mac 上打开 Xcode
2. 选择 `Assets.xcassets` → `AppIcon`
3. 拖入 1024×1024 PNG
4. Xcode 自动生成所有尺寸

### 方案 C：脚本自动化（当前使用）
- CI/CD 中 `generate_icons.py` 会自动生成
- 每次推送时自动转换

---

## 4️⃣ 推荐设计指南

| 要素 | 建议 |
|-----|------|
| 尺寸 | 1024×1024 为基准（最高质量） |
| 颜色 | RGB 或 RGBA（透明背景支持） |
| 内边距 | 左右 100px, 上下 100px |
| 格式 | PNG 32-bit（支持透明） |

---

## 5️⃣ 立即需要做什么

### ✅ 对于当前项目
1. 使用现有的 `AppLogo-1024.png`
2. CI/CD 会自动生成所有尺寸
3. 在 GitHub Actions → Artifacts 中下载 IPA

### 🎨 如果要优化图标
1. 制作 1024×1024 PNG
2. 保存为 `AppLogo-1024.png`（覆盖当前文件）
3. 推送到 GitHub
4. 等待 CI/CD 重新生成

---

## 📝 当前项目文件

```
iOS-Expense-Tracker/
├── AppLogo-1024.png                  ← 源图标文件
├── generate_icons.py                 ← 自动生成脚本
├── Assets.xcassets/AppIcon.appiconset/
│   ├── Contents.json                 ← 图标清单
│   └── [所有 PNG 由 CI/CD 生成]       ← 自动生成
└── .github/workflows/build-ipa.yml   ← CI/CD 配置
```

---

## 🚀 快速开始

### 选项 1：保持现状（推荐）
✅ AppLogo-1024.png → CI/CD 自动生成 → 完成

### 选项 2：上载新设计
1. 用 Figma/AI 生成设计
2. 保存为 `AppLogo-1024.png`
3. `git push`
4. 等待 CI/CD 重新生成 ✨
