# 🎨 小海帐 LOGO 快速集成指南

## ✅ 已完成的准备工作

- ✅ App 名称已改为 "小海帐"
- ✅ Assets.xcassets 目录结构已创建
- ✅ AppIcon.appiconset 文件夹已准备好
- ✅ project.yml 已配置为使用 Assets

## 📋 下一步：集成你的 LOGO

### 快速方案（推荐）

**使用在线工具自动生成所有尺寸：**

1. 访问 https://appicon.co
2. 上传你的 LOGO 图片（1024×1024 PNG）
3. 下载生成的 `.zip` 文件
4. 解压后将所有 PNG 文件复制到：
   ```
   iOS-Expense-Tracker/Assets.xcassets/AppIcon.appiconset/
   ```

### 高级方案（使用 ImageMagick）

如果你的系统已安装 ImageMagick，可以运行：

```bash
cd iOS-Expense-Tracker
bash setup-app-icon.sh
```

脚本会自动生成所有必须的尺寸。

## 📁 所需的文件清单

你的 LOGO 需要以下 11 个不同尺寸的 PNG 文件：

| 文件名 | 尺寸 | 用途 |
|--------|------|------|
| AppIcon-20@2x.png | 40×40 | iPhone 通知 |
| AppIcon-20@3x.png | 60×60 | iPhone Plus 通知 |
| AppIcon-29@2x.png | 58×58 | iPhone 设置 |
| AppIcon-29@3x.png | 87×87 | iPhone Plus 设置 |
| AppIcon-40@2x.png | 80×80 | iPhone 聚焦 |
| AppIcon-40@3x.png | 120×120 | iPhone Plus 聚焦 |
| AppIcon-60@2x.png | 120×120 | **iPhone 主屏幕** |
| AppIcon-60@3x.png | 180×180 | **iPhone Plus 主屏幕** |
| AppIcon-76@2x.png | 152×152 | iPad 主屏幕 |
| AppIcon-83.5@2x.png | 167×167 | iPad Pro 主屏幕 |
| AppIcon-1024.png | 1024×1024 | **App Store** |

**粗体** 的是最关键的版本。

## 🔧 验证集成

集成完成后，确保：

1. ✅ 所有 11 个 PNG 文件都在 `Assets.xcassets/AppIcon.appiconset/` 中
2. ✅ `Contents.json` 文件存在（已自动创建）
3. ✅ 文件名与 Contents.json 中的 "filename" 字段完全匹配

## 🚀 云端打包

完成上述步骤后：

```bash
git add Assets.xcassets/
git commit -m "feat: 添加小海帐 App Icon"
git push
```

CI/CD 会自动在下一次构建时使用新的 LOGO。

## 📞 常见问题

**Q: 图片文件太小怎么办？**
A: 使用放大工具（如 ImageMagick 的 `identify` 和 `convert`）检查尺寸，确保符合要求。

**Q: 图片看起来模糊？**
A: 确保源文件是 1024×1024，且是高清 PNG。在线工具通常会自动处理清晰度。

**Q: 我如何确认 LOGO 是否正确应用？**
A: 在 Xcode 中打开项目，选择 Target → General，向下滚动到 App Icons，应该能看到你的 LOGO 预览。

**Q: 可以跳过某些尺寸吗？**
A: 不建议。缺少任何尺寸可能导致构建失败或特定设备上显示默认图标。

---

**支持的 LOGO 格式：**
- PNG (推荐，支持透明通道)
- JPEG
- PDF (在 Contents.json 中需要特殊配置)

**LOGO 规范：**
- 避免圆角或透明区域被 iOS 自动处理
- 重要信息应在图像中心，不要靠近边缘
- 最多支持 Retina 分辨率（3x）
