import SwiftUI

struct AppTheme {
        // 主色调
    static let primaryColor = Color(red: 0.0, green: 0.48, blue: 1.0) // #007AFF - 蓝色
    static let primaryColorLight = Color(red: 0.2, green: 0.6, blue: 1.0) // 浅蓝色

    // 文本色
    static let textPrimary = Color(red: 0.0, green: 0.0, blue: 0.0) // 深黑色
    static let textSecondary = Color(red: 0.6, green: 0.6, blue: 0.6) // 灰色
    static let textTertiary = Color(red: 0.8, green: 0.8, blue: 0.8) // 浅灰色

    // 背景色
    static let backgroundPrimary = Color(red: 1.0, green: 1.0, blue: 1.0) // 白色
    static let backgroundSecondary = Color(red: 0.97, green: 0.97, blue: 0.97) // 浅灰背景
    static let backgroundTertiary = Color(red: 0.94, green: 0.94, blue: 0.96) // 更浅的背景

    // 功能色
    static let successColor = Color(red: 0.21, green: 0.78, blue: 0.35) // #34C759 - 绿色
    static let warningColor = Color(red: 1.0, green: 0.59, blue: 0.0) // #FF9500 - 橙色
    static let errorColor = Color(red: 1.0, green: 0.23, blue: 0.19) // #FF3B30 - 红色

    // 分割线色
    static let dividerColor = Color(red: 0.9, green: 0.9, blue: 0.9)

    // 圆角半径
    static let cornerRadiusMedium: CGFloat = 12
    static let cornerRadiusLarge: CGFloat = 16
    static let cornerRadiusSmall: CGFloat = 8

    // 间距
    static let spacingSmall: CGFloat = 8
    static let spacingMedium: CGFloat = 12
    static let spacingLarge: CGFloat = 16
    static let spacingXLarge: CGFloat = 24

    // 字体大小
    static let fontSizeSmall: CGFloat = 12
    static let fontSizeMedium: CGFloat = 14
    static let fontSizeLarge: CGFloat = 16
    static let fontSizeXLarge: CGFloat = 18
    static let fontSizeTitle: CGFloat = 24
}

// MARK: - 新的双色主题系统（V2.0）

struct ThemeColorSet {
    // 主色调
    let primaryColor: Color
    let primaryColorLight: Color

    // 次色调（科技赛博风格）
    let accentColor: Color
    let neonPurple: Color

    // 文本色
    let textPrimary: Color
    let textSecondary: Color
    let textTertiary: Color

    // 背景色
    let backgroundPrimary: Color
    let backgroundSecondary: Color
    let backgroundTertiary: Color

    // 边框和发光
    let borderColor: Color
    let glowColor: Color

    // 功能色
    let successColor: Color
    let warningColor: Color
    let errorColor: Color
}

/// 主题管理器 - 根据 colorScheme 环境变量提供不同配色
struct ThemeManager {
    @Environment(\.colorScheme) var colorScheme

    static func getColorSet(isDark: Bool) -> ThemeColorSet {
        if isDark {
            // 深色模式 - 科技赛博风格
            return ThemeColorSet(
                // 主色调 - 科技蓝
                primaryColor: Color(red: 0.0, green: 0.7, blue: 1.0),      // 霓虹蓝
                primaryColorLight: Color(red: 0.2, green: 0.8, blue: 1.0), // 浅霓虹蓝

                // 次色调 - 霓虹紫
                accentColor: Color(red: 0.7, green: 0.0, blue: 1.0),       // 霓虹紫
                neonPurple: Color(red: 0.8, green: 0.2, blue: 1.0),        // 浅霓虹紫

                // 文本色
                textPrimary: Color(red: 1.0, green: 1.0, blue: 1.0),       // 纯白
                textSecondary: Color(red: 0.7, green: 0.7, blue: 0.8),     // 浅灰蓝
                textTertiary: Color(red: 0.5, green: 0.5, blue: 0.6),      // 深灰蓝

                // 背景色 - 纯黑底
                backgroundPrimary: Color(red: 0.05, green: 0.05, blue: 0.08),   // 极深黑
                backgroundSecondary: Color(red: 0.1, green: 0.1, blue: 0.15),   // 深灰黑
                backgroundTertiary: Color(red: 0.15, green: 0.15, blue: 0.2),   // 灰黑

                // 边框和发光
                borderColor: Color(red: 0.0, green: 0.7, blue: 1.0).opacity(0.5),
                glowColor: Color(red: 0.0, green: 0.7, blue: 1.0).opacity(0.3),

                // 功能色
                successColor: Color(red: 0.0, green: 1.0, blue: 0.6),      // 霓虹绿
                warningColor: Color(red: 1.0, green: 0.7, blue: 0.0),      // 霓虹橙
                errorColor: Color(red: 1.0, green: 0.2, blue: 0.4)         // 霓虹红
            )
        } else {
            // 浅色模式 - 原生极简风格
            return ThemeColorSet(
                // 主色调
                primaryColor: Color(red: 0.0, green: 0.48, blue: 1.0),     // #007AFF - 蓝色
                primaryColorLight: Color(red: 0.2, green: 0.6, blue: 1.0), // 浅蓝色

                // 次色调
                accentColor: Color(red: 0.51, green: 0.33, blue: 0.86),    // 紫色
                neonPurple: Color(red: 0.63, green: 0.41, blue: 0.93),     // 浅紫色

                // 文本色
                textPrimary: Color(red: 0.0, green: 0.0, blue: 0.0),       // 深黑色
                textSecondary: Color(red: 0.6, green: 0.6, blue: 0.6),     // 灰色
                textTertiary: Color(red: 0.8, green: 0.8, blue: 0.8),      // 浅灰色

                // 背景色
                backgroundPrimary: Color(red: 1.0, green: 1.0, blue: 1.0), // 白色
                backgroundSecondary: Color(red: 0.97, green: 0.97, blue: 0.97), // 浅灰
                backgroundTertiary: Color(red: 0.94, green: 0.94, blue: 0.96),  // 更浅的灰

                // 边框和发光
                borderColor: Color(red: 0.9, green: 0.9, blue: 0.9),
                glowColor: Color(red: 0.95, green: 0.95, blue: 0.95),

                // 功能色
                successColor: Color(red: 0.21, green: 0.78, blue: 0.35),   // #34C759 - 绿色
                warningColor: Color(red: 1.0, green: 0.59, blue: 0.0),     // #FF9500 - 橙色
                errorColor: Color(red: 1.0, green: 0.23, blue: 0.19)       // #FF3B30 - 红色
            )
        }
    }
}

// MARK: - View 扩展，便捷访问主题颜色
extension View {
    func applyTheme(isDark: Bool) -> some View {
        // 获取对应主题的颜色集合
        _ = ThemeManager.getColorSet(isDark: isDark)
        return self
    }
}
