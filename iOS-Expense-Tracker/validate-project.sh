#!/bin/bash

# 项目验证脚本
# 用于验证 ExpenseTracker 项目结构是否完整

echo "🔍 验证 ExpenseTracker 项目结构..."
echo "======================================"

# 检查基本文件
required_files=(
    "ExpenseTracker.xcodeproj/project.pbxproj"
    "ExpenseTrackerApp.swift"
    "AppDelegate.swift"
    "Info.plist"
    "Models/Transaction.swift"
    "Models/Category.swift"
    "Views/ContentView.swift"
    "Views/AddTransactionView.swift"
)

missing_files=0

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file"
    else
        echo "❌ $file (缺失)"
        missing_files=$((missing_files + 1))
    fi
done

echo ""
echo "📁 检查目录结构..."
directories=(
    ".github/workflows"
    "Models"
    "Views"
)

for dir in "${directories[@]}"; do
    if [ -d "$dir" ]; then
        echo "✅ 目录: $dir"
        
        # 列出目录内容
        if [ "$dir" = ".github/workflows" ]; then
            echo "   工作流文件:"
            ls -1 "$dir"/*.yml 2>/dev/null || echo "   暂无工作流文件"
        fi
    else
        echo "❌ 目录: $dir (缺失)"
        missing_files=$((missing_files + 1))
    fi
done

echo ""
echo "🛠️ 检查 GitHub Actions 工作流..."
workflow_files=(
    ".github/workflows/ci.yml"
    ".github/workflows/build-ipa.yml"
    ".github/workflows/shipswift.yml"
)

for workflow in "${workflow_files[@]}"; do
    if [ -f "$workflow" ]; then
        echo "✅ $workflow"
        # 显示工作流名称
        workflow_name=$(grep -m1 "^name:" "$workflow" | cut -d: -f2- | sed 's/^ *//')
        echo "   名称: $workflow_name"
    else
        echo "⚠️  $workflow (可选)"
    fi
done

echo ""
echo "📊 统计信息:"
echo "Swift 文件数量: $(find . -name "*.swift" -type f | wc -l)"
echo "配置文件数量: $(find . -name "*.plist" -type f | wc -l)"
echo "工作流文件数量: $(find .github/workflows -name "*.yml" -type f 2>/dev/null | wc -l)"

echo ""
echo "======================================"
if [ $missing_files -eq 0 ]; then
    echo "🎉 项目结构完整！可以开始构建。"
    echo ""
    echo "下一步建议:"
    echo "1. 推送代码到 GitHub 仓库"
    echo "2. 在 GitHub Actions 中查看构建状态"
    echo "3. 使用手动触发测试构建流程"
    echo "4. 下载构建产物进行侧载测试"
else
    echo "⚠️  发现 $missing_files 个缺失文件/目录"
    echo "请检查并补充缺失的文件。"
fi

echo ""
echo "🚀 快速测试构建:"
echo "# 在 macOS 上运行:"
echo "xcodebuild clean build -project ExpenseTracker.xcodeproj -scheme ExpenseTracker -destination 'platform=iOS Simulator,name=iPhone 15'"
echo ""
echo "# 或使用脚本:"
echo "cd .github/workflows && ls -la"