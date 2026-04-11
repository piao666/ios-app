# 小海帐 iOS 项目说明

`小海帐` 是一个基于 `SwiftUI + SwiftData` 的 iOS 记账应用，当前代码已经整理到可持续维护的版本，支持中文界面、深浅色切换、语音记账、手动记账、交易编辑、分类管理、统计图表、月/年账本，以及 GitHub Actions 自动构建 IPA。

## 当前状态

当前仓库以 `E:\OpenClawWorkspace\iOS-Expense-Tracker` 为主工程目录，已经完成以下能力：

- 应用名称固定为 `小海帐`
- 竖屏 iPhone 全屏显示，避免内容缩成中间卡片
- 首页支持语音记账和手动记账
- 交易支持新增、编辑、删除
- 交易列表支持搜索和筛选
- 统计页支持支出分类环形图，并展示分类名称、金额、占比、笔数
- 账本页支持按月/按年切换查看，并可继续进入交易详情编辑
- 设置页支持分类管理、分类新增、删除、排序、图标选择、颜色选择
- 支持深色模式切换
- 已接入 App Icon 生成链路和 GitHub IPA 打包流程

## 当前工程结构

当前有效代码路径如下：

```text
E:\OpenClawWorkspace
├─ .github\workflows\
│  ├─ ci.yml
│  ├─ ios-build.yml
│  └─ build-ipa.yml
├─ README.md
└─ iOS-Expense-Tracker\
   ├─ project.yml
   ├─ AppMain.swift
   ├─ LaunchScreen.storyboard
   ├─ generate_icons.py
   ├─ Assets.xcassets\
   │  ├─ AppIcon.appiconset\
   │  └─ BrandLogo.imageset\
   └─ SourcesV2\
      ├─ Models.swift
      ├─ Theme.swift
      └─ Views\
         ├─ AddTransactionView.swift
         ├─ ContentView.swift
         ├─ DashboardView.swift
         ├─ ExpensePieChartView.swift
         ├─ LedgerView.swift
         ├─ SettingsView.swift
         ├─ TransactionDetailView.swift
         └─ TransactionListView.swift
```

说明：

- 当前真实入口是 `AppMain.swift`
- 当前真实源码目录是 `SourcesV2`
- 当前工程文件由 `XcodeGen` 根据 `project.yml` 生成
- `Assets.xcassets/BrandLogo.imageset/brand-logo.png` 是图标源资源之一
- 旧版 `Views/`、旧 `Info.plist`、旧报告类文件不应再作为主文档依据

## 已完成的实现路线

这一版仓库已经按下面的路线完成整理和修复：

1. 统一工程入口和构建方式  
   使用 `project.yml + XcodeGen` 生成 Xcode 工程，避免手改工程文件导致配置漂移。

2. 统一应用配置  
   将应用名称、图标名、权限说明、启动页、屏幕方向等信息放到 `project.yml` 管理，构建时生成 `Info.plist`。

3. 重建主界面结构  
   以 `ContentView.swift` 为四个主 Tab 入口：首页、交易、统计、设置。

4. 修复语音记账链路  
   语音录音与识别从不稳定的视图状态中剥离，改为独立管理对象，补齐麦克风和语音识别权限，并修复点击语音按钮闪退问题。

5. 修复页面比例与中文界面  
   恢复面向 iPhone 的正常布局，保留中文文案、深色模式入口、语音入口和交易编辑能力。

6. 完成交易与分类可编辑化  
   支持新增、编辑、删除交易；支持分类新增、编辑、删除、排序、图标与颜色选择。

7. 修复统计页显示  
   使用手动图例替代不稳定的系统图例，避免环形图比例异常、裁切或遮挡。

8. 接入图标与 IPA 产物链路  
   构建时自动从 `BrandLogo.imageset` 生成 `AppIcon`，并通过 GitHub Actions 产出可下载的 `.ipa`。

9. 修复交互命中问题  
   “保存这笔记录”和“更新”按钮已改为整块区域可点击，而不是只有文字可点击。

## 技术栈

- Swift 5.9
- SwiftUI
- SwiftData
- Charts
- AVFoundation
- Speech
- XcodeGen
- GitHub Actions

## 本地开发

### 环境要求

- Xcode 15 或更高版本
- iOS 17.0 或更高版本 SDK
- Ruby / Homebrew 非必需，但在 CI 中使用 Homebrew 安装 `xcodegen`

### 本地生成工程

在 `E:\OpenClawWorkspace\iOS-Expense-Tracker` 下执行：

```bash
xcodegen generate
```

生成后会得到 `ExpenseTracker.xcodeproj`。

### 本地运行测试

```bash
xcodebuild test \
  -project ExpenseTracker.xcodeproj \
  -scheme ExpenseTracker \
  -destination "platform=iOS Simulator,name=iPhone 15" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY=""
```

### 本地构建

```bash
xcodebuild clean build \
  -project ExpenseTracker.xcodeproj \
  -scheme ExpenseTracker \
  -destination "generic/platform=iOS" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY=""
```

## GitHub Actions 流程

仓库当前保留三条主要工作流：

- `ci.yml`
  用于分支提交和 Pull Request 的自动测试

- `ios-build.yml`
  用于主分支的通用 iOS 构建检查

- `build-ipa.yml`
  用于生成可下载的 `.ipa` 构建产物

### IPA 产出逻辑

`build-ipa.yml` 的流程如下：

1. 拉取代码
2. 安装 Python 和 Pillow
3. 读取 `Assets.xcassets/BrandLogo.imageset/brand-logo.png`
4. 生成 `AppIcon.appiconset` 所需尺寸图标
5. 通过 `xcodegen generate` 生成工程
6. 编译 Release 版本
7. 打包 `ExpenseTracker.app` 为 `ExpenseTracker.ipa`
8. 上传到 GitHub Actions Artifact

## 提交与同步

如果你在本地删除了旧文件，想同步到 GitHub，标准命令如下：

```bash
git add -A
git commit -m "chore: cleanup obsolete files"
git push origin <your-branch>
```

如果要把当前工作分支合并到 `main`，建议通过 Pull Request 合并；也可以本地先切到 `main` 再合并。

## 维护约定

- 文档以当前 `SourcesV2` 结构为准
- 应用配置以 `project.yml` 为准
- 图标资源以 `Assets.xcassets` 为准
- 如果后续再做 UI 或交互重构，先改源码，再同步更新本 README

## 版本说明

这份 README 对应的是当前已经完成一轮完整整理后的工程版本，重点不再是“原始样例项目”，而是“已修复并可持续打包的小海帐 iOS 应用”。
