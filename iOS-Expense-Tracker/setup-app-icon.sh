#!/bin/bash

# 小海帐 LOGO 自动化集成脚本
# Usage: bash setup-app-icon.sh [source_logo_path]

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS_DIR="$PROJECT_DIR/Assets.xcassets"
APPICON_DIR="$ASSETS_DIR/AppIcon.appiconset"

echo "🎨 开始设置小海帐 App Icon..."
echo "📂 项目目录: $PROJECT_DIR"

# 创建目录结构
mkdir -p "$APPICON_DIR"
echo "✅ 已创建 Assets.xcassets 目录"

# 创建 Contents.json
cat > "$APPICON_DIR/Contents.json" << 'EOF'
{
  "images" : [
    {
      "filename" : "AppIcon-20@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "filename" : "AppIcon-20@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "20x20"
    },
    {
      "filename" : "AppIcon-29@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "filename" : "AppIcon-29@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "29x29"
    },
    {
      "filename" : "AppIcon-40@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "filename" : "AppIcon-40@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "40x40"
    },
    {
      "filename" : "AppIcon-60@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "60x60"
    },
    {
      "filename" : "AppIcon-60@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "60x60"
    },
    {
      "filename" : "AppIcon-76@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "76x76"
    },
    {
      "filename" : "AppIcon-83.5@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "83.5x83.5"
    },
    {
      "filename" : "AppIcon-1024.png",
      "idiom" : "ios-marketing",
      "scale" : "1x",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "OpenClaw",
    "version" : 1
  }
}
EOF

echo "✅ 已创建 Contents.json 配置文件"

# 创建占位符 PNG 文件（如果安装了 ImageMagick）
if command -v convert &> /dev/null; then
    echo "🖼️  使用 ImageMagick 生成占位符图片..."

    # 临时 LOGO 颜色（粉色系渐变）
    LOGO_COLOR="pink"

    # 生成各种尺寸的占位符
    convert -size 40x40 "xc:$LOGO_COLOR" "$APPICON_DIR/AppIcon-20@2x.png"
    convert -size 60x60 "xc:$LOGO_COLOR" "$APPICON_DIR/AppIcon-20@3x.png"
    convert -size 58x58 "xc:$LOGO_COLOR" "$APPICON_DIR/AppIcon-29@2x.png"
    convert -size 87x87 "xc:$LOGO_COLOR" "$APPICON_DIR/AppIcon-29@3x.png"
    convert -size 80x80 "xc:$LOGO_COLOR" "$APPICON_DIR/AppIcon-40@2x.png"
    convert -size 120x120 "xc:$LOGO_COLOR" "$APPICON_DIR/AppIcon-40@3x.png"
    convert -size 120x120 "xc:$LOGO_COLOR" "$APPICON_DIR/AppIcon-60@2x.png"
    convert -size 180x180 "xc:$LOGO_COLOR" "$APPICON_DIR/AppIcon-60@3x.png"
    convert -size 152x152 "xc:$LOGO_COLOR" "$APPICON_DIR/AppIcon-76@2x.png"
    convert -size 167x167 "xc:$LOGO_COLOR" "$APPICON_DIR/AppIcon-83.5@2x.png"
    convert -size 1024x1024 "xc:$LOGO_COLOR" "$APPICON_DIR/AppIcon-1024.png"

    echo "✅ 已生成所有尺寸的占位符图片"
else
    echo "⚠️  请手动添加以下尺寸的 LOGO 文件到 $APPICON_DIR："
    echo "   - AppIcon-20@2x.png (40x40)"
    echo "   - AppIcon-20@3x.png (60x60)"
    echo "   - AppIcon-29@2x.png (58x58)"
    echo "   - AppIcon-29@3x.png (87x87)"
    echo "   - AppIcon-40@2x.png (80x80)"
    echo "   - AppIcon-40@3x.png (120x120)"
    echo "   - AppIcon-60@2x.png (120x120)"
    echo "   - AppIcon-60@3x.png (180x180)"
    echo "   - AppIcon-76@2x.png (152x152)"
    echo "   - AppIcon-83.5@2x.png (167x167)"
    echo "   - AppIcon-1024.png (1024x1024)"
fi

echo ""
echo "🎉 App Icon 设置完成！"
echo "📍 Assets 位置: $ASSETS_DIR"
echo ""
echo "📋 后续步骤："
echo "1. 将您的 LOGO (1024x1024 PNG) 放入 Assets.xcassets"
echo "2. 在本地 Xcode 中打开项目并使用 AppIcon 生成工具自动缩放"
echo "3. 或使用在线工具 (https://appicon.co) 生成所有尺寸"
echo ""
