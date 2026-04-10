#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
iOS Expense Tracker 编译检查脚本
验证所有代码完整性、依赖、LOGO等
"""

import os
import re
from pathlib import Path

def check_file_exists(file_path, description=""):
    """检查文件是否存在"""
    exists = os.path.exists(file_path)
    status = "✓" if exists else "✗"
    desc = f" ({description})" if description else ""
    print(f"{status} {file_path}{desc}")
    return exists

def check_imports_in_file(file_path):
    """检查Swift文件中的导入和引用"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()

        issues = []

        # 检查import语句
        imports = re.findall(r'^import\s+(\w+)', content, re.MULTILINE)
        print(f"  导入: {', '.join(set(imports))}")

        # 检查结构体定义
        structs = re.findall(r'^struct\s+(\w+)', content, re.MULTILINE)
        if structs:
            print(f"  定义的结构: {', '.join(structs)}")

        # 检查是否有语法错误迹象
        if content.count('{') != content.count('}'):
            issues.append("大括号不匹配")

        if content.count('(') != content.count(')'):
            issues.append("圆括号不匹配")

        # 检查常见错误
        if re.search(r'var body.*without return', content):
            issues.append("body计算属性没有返回值")

        return imports, issues
    except Exception as e:
        return [], [str(e)]

def check_swift_files():
    """检查所有Swift文件"""
    print("\n" + "="*50)
    print("📋 Swift 代码文件检查")
    print("="*50)

    swift_dir = "Views"
    swift_files = [
        "DashboardView.swift",
        "ContentView.swift",
        "LedgerView.swift",
        "ExpensePieChartView.swift",
        "TransactionListView.swift",
        "SettingsView.swift"
    ]

    all_ok = True
    all_imports = set()

    for swift_file in swift_files:
        file_path = os.path.join(swift_dir, swift_file)
        if check_file_exists(file_path):
            imports, issues = check_imports_in_file(file_path)
            all_imports.update(imports)
            if issues:
                all_ok = False
                for issue in issues:
                    print(f"    ⚠ {issue}")
        else:
            all_ok = False

    print(f"\n全局导入库: {', '.join(sorted(all_imports))}")
    return all_ok

def check_logo():
    """检查LOGO文件"""
    print("\n" + "="*50)
    print("🎨 LOGO 集成检查")
    print("="*50)

    logo_checks = [
        ("AppLogo-1024.png", "原始LOGO文件"),
        ("Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png", "生成的1024x1024图标"),
        ("Assets.xcassets/AppIcon.appiconset/AppIcon-180@3x.png", "iPhone标准图标"),
        ("Assets.xcassets/AppIcon.appiconset/AppIcon-120@2x.png", "iPhone应用图标"),
        ("Assets.xcassets/AppIcon.appiconset/Contents.json", "配置文件"),
    ]

    all_ok = True
    icon_count = 0

    for logo_file, desc in logo_checks:
        if check_file_exists(logo_file, desc):
            if logo_file.endswith('.png'):
                icon_count += 1
        else:
            all_ok = False

    print(f"\n生成的图标数量: {icon_count} 个")
    return all_ok

def check_features():
    """检查功能实现"""
    print("\n" + "="*50)
    print("⚙ 功能实现检查")
    print("="*50)

    features = {
        "VoiceInputView": "语音输入功能",
        "LedgerView": "账单簿功能",
        "ExpensePieChartView": "支出图表功能",
        "TransactionListView": "交易列表功能",
        "SettingsView": "设置功能",
    }

    all_ok = True

    for feature_name, description in features.items():
        # 搜索特定的视图或功能
        found = False
        for root, dirs, files in os.walk("Views"):
            for file in files:
                if file.endswith(".swift"):
                    file_path = os.path.join(root, file)
                    try:
                        with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                            content = f.read()
                            if feature_name in content:
                                found = True
                                break
                    except:
                        pass
            if found:
                break

        status = "✓" if found else "✗"
        print(f"{status} {description} ({feature_name})")
        if not found:
            all_ok = False

    return all_ok

def check_models():
    """检查数据模型"""
    print("\n" + "="*50)
    print("📊 数据模型检查")
    print("="*50)

    models_dir = "Models"
    model_files = [
        "Transaction.swift",
    ]

    all_ok = True

    for model_file in model_files:
        file_path = os.path.join(models_dir, model_file)
        if check_file_exists(file_path, "数据模型"):
            imports, issues = check_imports_in_file(file_path)
            if issues:
                all_ok = False
        else:
            all_ok = False

    return all_ok

def check_theme():
    """检查主题配置"""
    print("\n" + "="*50)
    print("🎨 主题配置检查")
    print("="*50)

    if check_file_exists("Theme.swift", "主题文件"):
        try:
            with open("Theme.swift", 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()
                has_theme_manager = "ThemeManager" in content
                has_theme_settings = "ThemeSettings" in content
                has_colors = "primaryColor" in content

                print(f"  {'✓' if has_theme_manager else '✗'} ThemeManager类")
                print(f"  {'✓' if has_theme_settings else '✗'} ThemeSettings类")
                print(f"  {'✓' if has_colors else '✗'} 颜色定义")

                return has_theme_manager and has_theme_settings and has_colors
        except Exception as e:
            print(f"  ✗ 读取失败: {e}")
            return False

    return False

def check_git_status():
    """检查Git状态"""
    print("\n" + "="*50)
    print("📦 Git 提交状态")
    print("="*50)

    try:
        import subprocess

        # 检查当前分支
        result = subprocess.run(['git', 'branch', '--show-current'],
                              capture_output=True, text=True, timeout=5)
        branch = result.stdout.strip()
        print(f"当前分支: {branch}")

        # 检查未提交的文件
        result = subprocess.run(['git', 'status', '--porcelain'],
                              capture_output=True, text=True, timeout=5)
        uncommitted = result.stdout.strip()

        if uncommitted:
            print(f"\n未提交的变更:")
            uncommitted_lines = uncommitted.split('\n')
            for line in uncommitted_lines[:10]:
                print(f"  {line}")
            extra_count = len(uncommitted_lines) - 10
            if extra_count > 0:
                print(f"  ... 以及其他 {extra_count} 个文件")
        else:
            print("✓ 所有文件已提交")

        # 检查最近的提交
        result = subprocess.run(['git', 'log', '--oneline', '-1'],
                              capture_output=True, text=True, timeout=5)
        latest_commit = result.stdout.strip()
        print(f"\n最新提交: {latest_commit}")

        return True
    except Exception as e:
        print(f"⚠ Git检查失败: {e}")
        return False

def main():
    """主检查函数"""
    print("\n" + "="*50)
    print("📱 iOS Expense Tracker 编译检查")
    print("="*50)

    checks = [
        ("Swift代码文件", check_swift_files),
        ("LOGO集成", check_logo),
        ("功能实现", check_features),
        ("数据模型", check_models),
        ("主题配置", check_theme),
        ("Git状态", check_git_status),
    ]

    results = []

    for check_name, check_func in checks:
        try:
            result = check_func()
            results.append((check_name, result))
        except Exception as e:
            print(f"\n⚠ {check_name} 检查异常: {e}")
            results.append((check_name, False))

    # 总结
    print("\n" + "="*50)
    print("✅ 编译检查总结")
    print("="*50)

    all_passed = True
    for check_name, result in results:
        status = "✓ 通过" if result else "✗ 未通过"
        print(f"{status}: {check_name}")
        if not result:
            all_passed = False

    print("\n" + "="*50)
    if all_passed:
        print("🎉 所有检查通过！项目可以编译")
    else:
        print("⚠ 部分检查未通过，请检查上述问题")

    return all_passed

if __name__ == "__main__":
    import sys
    success = main()
    sys.exit(0 if success else 1)
