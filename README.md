# iOS 个人记账应用 - ExpenseTracker

一个使用 SwiftUI + SwiftData 开发的个人记账应用，专为 iOS 设计。

## 项目特点

- 🎯 **纯 SwiftUI** - 现代化的声明式 UI
- 💾 **SwiftData** - 本地数据存储
- 📱 **iOS 原生** - 最佳的性能和用户体验
- 🚀 **云端构建** - 无需本地 macOS 环境
- 🔧 **侧载部署** - 个人使用，无需上架 App Store

## 技术栈

- **语言**: Swift 5.9+
- **UI 框架**: SwiftUI
- **数据存储**: SwiftData
- **最低版本**: iOS 17.0+
- **构建工具**: Xcode 15+

## 项目结构

```
iOS-Expense-Tracker/
├── ExpenseTracker.xcodeproj/     # Xcode 项目文件
├── Models/                       # 数据模型
│   ├── Transaction.swift         # 交易模型
│   └── Category.swift            # 分类模型
├── Views/                        # 视图组件
│   ├── ContentView.swift         # 主界面
│   └── AddTransactionView.swift  # 添加交易界面
├── ExpenseTrackerApp.swift       # 应用入口
├── AppDelegate.swift             # App 代理
├── main.m                        # Objective-C 入口
├── Info.plist                    # 应用配置
└── LaunchScreen.storyboard       # 启动屏幕
```

## 核心功能

### 已实现
- ✅ 交易记录（收入/支出）
- ✅ 分类管理
- ✅ 数据持久化（SwiftData）
- ✅ 基本的 UI 界面
- ✅ 添加/删除交易

### 计划中
- 📊 统计图表
- 💰 预算管理
- ☁️ 数据备份
- 🔔 提醒功能
- 📱 Widget 支持

## 开发环境

### 本地开发（无需 macOS）
1. **代码编写**: VS Code + Swift 扩展
2. **版本控制**: Git
3. **协作工具**: Claude 模型辅助编程

### 云端构建 (CI/CD)
项目配置了完整的 GitHub Actions 工作流：

#### 可用工作流：
1. **CI 工作流** (`/.github/workflows/ci.yml`)
   - 自动构建验证
   - 代码质量检查
   - 文档自动部署
   - 触发条件：push 到 main/develop 分支

2. **IPA 构建工作流** (`/.github/workflows/build-ipa.yml`)
   - 生成侧载用的 IPA 文件
   - 开发证书签名
   - 触发条件：push 到 main 分支或手动触发

3. **ShipSwift 集成工作流** (`/.github/workflows/shipswift.yml`)
   - ShipSwift MCP 服务集成
   - 高级构建配置
   - 触发条件：手动触发或特定文件变更

#### 构建环境：
- **Runner**: macOS latest
- **Xcode**: 最新版本
- **输出产物**: .ipa 文件 + 构建日志
- **部署方式**: 侧载（Sideloadly/AltStore）

## 快速开始

### 1. 克隆项目
```bash
git clone <repository-url>
cd iOS-Expense-Tracker
```

### 2. 配置项目
1. 打开 `ExpenseTracker.xcodeproj`
2. 修改 Bundle Identifier
3. 配置开发团队

### 3. 云端构建
#### 自动构建（推荐）：
1. 推送代码到 GitHub main 分支
2. GitHub Actions 自动触发构建
3. 在 Actions 标签页查看构建状态
4. 下载生成的构建产物

#### 手动构建：
1. 访问 GitHub Actions 页面
2. 选择 "Build IPA for Side-loading" 工作流
3. 点击 "Run workflow"
4. 选择分支并运行

### 4. 下载构建产物
1. 构建完成后，进入 Actions 页面
2. 点击成功的构建运行
3. 在 "Artifacts" 部分下载 `expense-tracker-build`
4. 解压后找到 IPA 文件

### 5. 侧载安装
1. **使用 AltStore**:
   - 安装 AltServer 到电脑
   - 连接 iPhone，安装 AltStore
   - 通过 AltStore 安装 IPA 文件

2. **使用 Sideloadly**:
   - 下载 Sideloadly
   - 连接 iPhone
   - 拖入 IPA 文件并安装

3. **信任开发者证书**:
   - 进入 iPhone 设置 > 通用 > VPN 与设备管理
   - 找到开发者应用，点击信任

## 开发工作流

### 日常开发
```bash
# 1. 在 VS Code 中编写 Swift 代码
# 2. 提交更改
git add .
git commit -m "功能描述"

# 3. 推送到 GitHub
git push origin main

# 4. 等待 CI/CD 构建
# 5. 下载并侧载安装
```

### ShipSwift MCP 集成
ShipSwift 是一个 MCP（Model Context Protocol）服务器，用于自动化 iOS 应用构建：

#### 安装 ShipSwift MCP：
```bash
# 全局安装
npm install -g @shipswift/mcp-server

# 或在项目中安装
npm install --save-dev @shipswift/mcp-server
```

#### 配置 Claude Desktop：
在 Claude Desktop 的配置文件中添加：
```json
{
  "mcpServers": {
    "shipswift": {
      "command": "npx",
      "args": ["@shipswift/mcp-server"]
    }
  }
}
```

#### 可用功能：
- 自动构建 iOS 应用
- 代码质量检查
- 构建报告生成
- 与 GitHub Actions 集成

#### 使用示例：
通过 Claude 与 ShipSwift 交互：
```
@shipswift 构建 ExpenseTracker 项目
@shipswift 检查代码质量
@shipswift 生成构建报告
```

### 代码规范
- 使用 SwiftLint 保持代码风格一致
- 遵循 Swift API 设计指南
- 使用有意义的命名
- 添加必要的注释

## 贡献指南

1. Fork 本仓库
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

## 许可证

本项目仅供个人学习使用。

## 联系方式

如有问题或建议，请通过 GitHub Issues 反馈。

---

**最后更新**: 2026-03-31 14:45
**版本**: 1.1.0 (添加 CI/CD 工作流)
**构建状态**: [![CI](https://github.com/username/repo/actions/workflows/ci.yml/badge.svg)](https://github.com/username/repo/actions/workflows/ci.yml)