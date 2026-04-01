# 小海帐 LOGO 集成指南

## 📦 LOGO 规格信息

**LOGO 名称**：小海帐 App Icon
**设计风格**：粉色渐变叠浪 + WiFi 信号元素
**格式**：PNG (支持透明度)

## 🎯 集成步骤

### 方法 A：通过 Xcode 手动集成（推荐用于本地开发）

1. **在 Xcode 中打开项目**
   ```
   iOS-Expense-Tracker/ExpenseTracker.xcodeproj
   ```

2. **创建 Assets.xcassets**
   - 右键项目 → New → Asset Catalog
   - 命名为 `Assets`

3. **添加 App Icon Set**
   - 在 Assets.xcassets 中右键 → New → App Icon Set
   - 命名为 `AppIcon`

4. **导入 LOGO 文件**
   - 需要以下尺寸的图片（像素）：
     - iPhone 20pt (iPhone SE, 3rd gen, Home screen)
     - iPhone 40pt (iPhone, iPad, Home screen)
     - iPhone 60pt (iPhone, Home screen)
     - iPhone 76pt (iPad, Home screen)
     - iPhone 83.5pt (iPad Pro, Home screen)
     - iPhone 1024pt (App Store)

5. **自动生成所有尺寸**
   - 推荐使用在线工具 (如 https://appicon.co/) 或 Xcode 内置功能
   - 上传 1024x1024 版本，自动生成所有尺寸

6. **更新 Info.plist**
   ```xml
   <key>CFBundleIcons</key>
   <dict>
       <key>CFBundlePrimaryIcon</key>
       <dict>
           <key>CFBundleIconFiles</key>
           <array>
               <string>AppIcon</string>
           </array>
       </dict>
   </dict>
   ```

### 方法 B：通过脚本自动集成（推荐用于 CI/CD）

创建 `setup-assets.sh` 脚本：

```bash
#!/bin/bash

# 创建 Assets.xcassets 目录结构
mkdir -p Assets.xcassets/AppIcon.appiconset

# Contents.json 配置文件
cat > Assets.xcassets/AppIcon.appiconset/Contents.json << 'EOF'
{
  "images": [
    {
      "filename": "AppIcon-20@2x.png",
      "idiom": "iphone",
      "scale": "2x",
      "size": "20x20"
    },
    {
      "filename": "AppIcon-20@3x.png",
      "idiom": "iphone",
      "scale": "3x",
      "size": "20x20"
    },
    {
      "filename": "AppIcon-29@2x.png",
      "idiom": "iphone",
      "scale": "2x",
      "size": "29x29"
    },
    {
      "filename": "AppIcon-29@3x.png",
      "idiom": "iphone",
      "scale": "3x",
      "size": "29x29"
    },
    {
      "filename": "AppIcon-40@2x.png",
      "idiom": "iphone",
      "scale": "2x",
      "size": "40x40"
    },
    {
      "filename": "AppIcon-40@3x.png",
      "idiom": "iphone",
      "scale": "3x",
      "size": "40x40"
    },
    {
      "filename": "AppIcon-60@2x.png",
      "idiom": "iphone",
      "scale": "2x",
      "size": "60x60"
    },
    {
      "filename": "AppIcon-60@3x.png",
      "idiom": "iphone",
      "scale": "3x",
      "size": "60x60"
    },
    {
      "filename": "AppIcon-1024.png",
      "idiom": "ios-marketing",
      "scale": "1x",
      "size": "1024x1024"
    }
  ],
  "info": {
    "author": "OpenClaw",
    "version": 1
  }
}
EOF

echo "✅ Assets.xcassets 结构已创建，请将 LOGO 文件复制到对应的文件夹中"
```

## 🖼️ LOGO 文件清单

需要以下图片文件放在 `Assets.xcassets/AppIcon.appiconset/` 目录：

| 文件名 | 尺寸 | 用途 |
|--------|------|------|
| AppIcon-20@2x.png | 40x40 | iPhone 通知栏、控制中心 |
| AppIcon-20@3x.png | 60x60 | iPhone Plus 通知栏、控制中心 |
| AppIcon-29@2x.png | 58x58 | iPhone 设置 |
| AppIcon-29@3x.png | 87x87 | iPhone Plus 设置 |
| AppIcon-40@2x.png | 80x80 | iPhone 聚焦搜索结果 |
| AppIcon-40@3x.png | 120x120 | iPhone Plus 聚焦搜索结果 |
| AppIcon-60@2x.png | 120x120 | iPhone 主屏幕 |
| AppIcon-60@3x.png | 180x180 | iPhone Plus 主屏幕 |
| AppIcon-1024.png | 1024x1024 | App Store |

## 🚀 推荐工具

- **Figma**：调整 LOGO 尺寸和导出 (https://www.figma.com)
- **Photoshop/GIMP**：编辑和缩放
- **AppIcon.co**：在线一键生成所有尺寸 (免费)
- **ImageMagick**：命令行批量转换

## 📝 CI/CD 集成

在 `project.yml` 中添加：

```yaml
targets:
  ExpenseTracker:
    resources:
      - path: Assets.xcassets
```

然后在 `.github/workflows/build-ipa.yml` 中添加：

```yaml
- name: Setup App Assets
  working-directory: ./iOS-Expense-Tracker
  run: bash setup-assets.sh
```
