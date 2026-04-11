#!/usr/bin/env python3
"""
小海帐 LOGO 自动化处理脚本
从 1024×1024 源图片生成所有必需的 App Icon 尺寸
"""

import os
import sys
import io
from PIL import Image
from PIL import ImageOps

# 修复 Windows 编码问题
if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

def generate_app_icons(source_image_path, output_dir):
    """生成所有必需的 App Icon 尺寸"""

    # 定义需要生成的图标尺寸
    sizes = {
        'AppIcon-20@2x.png': (40, 40),
        'AppIcon-20@3x.png': (60, 60),
        'AppIcon-29@2x.png': (58, 58),
        'AppIcon-29@3x.png': (87, 87),
        'AppIcon-40@2x.png': (80, 80),
        'AppIcon-40@3x.png': (120, 120),
        'AppIcon-60@2x.png': (120, 120),
        'AppIcon-60@3x.png': (180, 180),
        'AppIcon-76@2x.png': (152, 152),
        'AppIcon-83.5@2x.png': (167, 167),
        'AppIcon-1024.png': (1024, 1024),
    }

    try:
        # 打开源图片
        if not os.path.exists(source_image_path):
            print(f"❌ 错误：找不到源图片 {source_image_path}")
            return False

        print(f"📖 打开源图片: {source_image_path}")
        source_img = Image.open(source_image_path).convert('RGBA')
        source_square = ImageOps.fit(
            source_img,
            (1024, 1024),
            method=Image.Resampling.LANCZOS,
            centering=(0.5, 0.5)
        )

        # 确保输出目录存在
        os.makedirs(output_dir, exist_ok=True)

        # 生成所有尺寸
        print(f"\n🎨 生成 {len(sizes)} 种尺寸的 App Icon...\n")

        for filename, (width, height) in sizes.items():
            # 缩放图片
            resized_img = source_square.resize((width, height), Image.Resampling.LANCZOS)

            # 转换为 RGB（PNG 格式）
            output_path = os.path.join(output_dir, filename)
            rgb_img = Image.new('RGB', resized_img.size, (255, 255, 255))
            rgb_img.paste(resized_img, mask=resized_img.split()[3])
            rgb_img.save(output_path, 'PNG')

            print(f"  ✅ {filename:25s} ({width:4d}×{height:4d}px)")

        print(f"\n🎉 成功生成所有 App Icon 文件！")
        print(f"📍 输出目录: {output_dir}\n")
        return True

    except Exception as e:
        print(f"❌ 错误: {str(e)}")
        return False

def main():
    # 获取脚本所在目录
    script_dir = os.path.dirname(os.path.abspath(__file__))

    # 定义路径
    source_logo = os.path.join(script_dir, 'AppLogo-1024.png')  # 你的源 LOGO
    output_dir = os.path.join(script_dir, 'Assets.xcassets', 'AppIcon.appiconset')

    # 如果用户提供了参数，使用参数指定的源图片
    if len(sys.argv) > 1:
        source_logo = sys.argv[1]

    # 检查源图片是否存在
    if not os.path.exists(source_logo):
        print(f"⚠️  提示：")
        print(f"  请将你的 LOGO 图片（1024×1024 PNG）复制到：")
        print(f"  {source_logo}\n")
        print(f"  或者运行：")
        print(f"  python3 generate_icons.py /path/to/your/logo.png\n")
        return False

    # 生成图标
    return generate_app_icons(source_logo, output_dir)

if __name__ == '__main__':
    success = main()
    sys.exit(0 if success else 1)
