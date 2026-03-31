#!/bin/bash

# iOS Expense Tracker 构建脚本
echo "🏗️ Building iOS Expense Tracker..."

# 清理之前的构建
rm -rf build
mkdir -p build

# 显示项目信息
echo "📱 Project: ExpenseTracker"
echo "📦 Bundle ID: com.haizong.ExpenseTracker"
echo "📁 Working directory: $(pwd)"

# 检查 Xcode 项目
if [ ! -f "ExpenseTracker.xcodeproj/project.pbxproj" ]; then
    echo "❌ Error: Xcode project not found!"
    ls -la
    exit 1
fi

# 显示 Xcode 版本
echo "🛠️ Xcode version:"
xcodebuild -version

# 构建项目（模拟器）
echo "🔨 Building for iOS Simulator..."
xcodebuild clean build \
    -project ExpenseTracker.xcodeproj \
    -scheme ExpenseTracker \
    -configuration Debug \
    -destination 'platform=iOS Simulator,name=iPhone 15' \
    CODE_SIGNING_ALLOWED=NO \
    | xcpretty

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    
    # 创建构建信息文件
    cat > build/build-info.json << EOF
{
    "success": true,
    "project": "ExpenseTracker",
    "bundleId": "com.haizong.ExpenseTracker",
    "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "platform": "iOS Simulator",
    "configuration": "Debug",
    "scheme": "ExpenseTracker"
}
EOF
    
    # 显示构建产物
    echo "📦 Build artifacts:"
    find build -type f -name "*.app" -o -name "*.dSYM" | head -10
    
else
    echo "❌ Build failed!"
    exit 1
fi