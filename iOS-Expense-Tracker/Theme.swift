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
