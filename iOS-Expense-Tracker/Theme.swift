import SwiftUI

struct AppTheme {
    // 主色调
    static let primaryColor = Color(red: 0.0, green: 0.48, blue: 1.0)
    static let primaryColorLight = Color(red: 0.2, green: 0.6, blue: 1.0)

    // 文本色
    static let textPrimary = Color(red: 0.0, green: 0.0, blue: 0.0)
    static let textSecondary = Color(red: 0.6, green: 0.6, blue: 0.6)
    static let textTertiary = Color(red: 0.8, green: 0.8, blue: 0.8)

    // 背景色
    static let backgroundPrimary = Color(red: 1.0, green: 1.0, blue: 1.0)
    static let backgroundSecondary = Color(red: 0.97, green: 0.97, blue: 0.97)
    static let backgroundTertiary = Color(red: 0.94, green: 0.94, blue: 0.96)

    // 功能色
    static let successColor = Color(red: 0.21, green: 0.78, blue: 0.35)
    static let warningColor = Color(red: 1.0, green: 0.59, blue: 0.0)
    static let errorColor = Color(red: 1.0, green: 0.23, blue: 0.19)

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

// MARK: - 双色主题系统

struct ThemeColorSet {
    let primaryColor: Color
    let primaryColorLight: Color
    let accentColor: Color
    let neonPurple: Color
    let textPrimary: Color
    let textSecondary: Color
    let textTertiary: Color
    let backgroundPrimary: Color
    let backgroundSecondary: Color
    let backgroundTertiary: Color
    let borderColor: Color
    let glowColor: Color
    let successColor: Color
    let warningColor: Color
    let errorColor: Color
}

struct ThemeManager {
    static func getColorSet(isDark: Bool) -> ThemeColorSet {
        if isDark {
            return ThemeColorSet(
                primaryColor: Color(red: 0.0, green: 0.7, blue: 1.0),
                primaryColorLight: Color(red: 0.2, green: 0.8, blue: 1.0),
                accentColor: Color(red: 0.7, green: 0.0, blue: 1.0),
                neonPurple: Color(red: 0.8, green: 0.2, blue: 1.0),
                textPrimary: Color(red: 1.0, green: 1.0, blue: 1.0),
                textSecondary: Color(red: 0.7, green: 0.7, blue: 0.8),
                textTertiary: Color(red: 0.5, green: 0.5, blue: 0.6),
                backgroundPrimary: Color(red: 0.05, green: 0.05, blue: 0.08),
                backgroundSecondary: Color(red: 0.1, green: 0.1, blue: 0.15),
                backgroundTertiary: Color(red: 0.15, green: 0.15, blue: 0.2),
                borderColor: Color(red: 0.0, green: 0.7, blue: 1.0).opacity(0.5),
                glowColor: Color(red: 0.0, green: 0.7, blue: 1.0).opacity(0.3),
                successColor: Color(red: 0.0, green: 1.0, blue: 0.6),
                warningColor: Color(red: 1.0, green: 0.7, blue: 0.0),
                errorColor: Color(red: 1.0, green: 0.2, blue: 0.4)
            )
        } else {
            return ThemeColorSet(
                primaryColor: Color(red: 0.0, green: 0.48, blue: 1.0),
                primaryColorLight: Color(red: 0.2, green: 0.6, blue: 1.0),
                accentColor: Color(red: 0.51, green: 0.33, blue: 0.86),
                neonPurple: Color(red: 0.63, green: 0.41, blue: 0.93),
                textPrimary: Color(red: 0.0, green: 0.0, blue: 0.0),
                textSecondary: Color(red: 0.6, green: 0.6, blue: 0.6),
                textTertiary: Color(red: 0.8, green: 0.8, blue: 0.8),
                backgroundPrimary: Color(red: 1.0, green: 1.0, blue: 1.0),
                backgroundSecondary: Color(red: 0.97, green: 0.97, blue: 0.97),
                backgroundTertiary: Color(red: 0.94, green: 0.94, blue: 0.96),
                borderColor: Color(red: 0.9, green: 0.9, blue: 0.9),
                glowColor: Color(red: 0.95, green: 0.95, blue: 0.95),
                successColor: Color(red: 0.21, green: 0.78, blue: 0.35),
                warningColor: Color(red: 1.0, green: 0.59, blue: 0.0),
                errorColor: Color(red: 1.0, green: 0.23, blue: 0.19)
            )
        }
    }
}

// MARK: - 全局主题状态（AppStorage 持久化，EnvironmentObject 广播）
class ThemeSettings: ObservableObject {
    @AppStorage("app_isDarkMode") var isDarkMode: Bool = false
}