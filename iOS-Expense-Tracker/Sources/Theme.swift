import SwiftUI

struct AppTheme {
    static let primaryColor = Color(red: 0.0, green: 0.48, blue: 1.0)
    static let primaryColorLight = Color(red: 0.2, green: 0.6, blue: 1.0)

    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    static let textTertiary = Color.secondary.opacity(0.7)

    static let backgroundPrimary = Color(.systemBackground)
    static let backgroundSecondary = Color(.secondarySystemBackground)
    static let backgroundTertiary = Color(.tertiarySystemBackground)

    static let successColor = Color.green
    static let warningColor = Color.orange
    static let errorColor = Color.red

    static let borderColor = Color(.separator)
    static let dividerColor = Color(.separator)

    static let cornerRadiusSmall: CGFloat = 8
    static let cornerRadiusMedium: CGFloat = 12
    static let cornerRadiusLarge: CGFloat = 16

    static let spacingSmall: CGFloat = 8
    static let spacingMedium: CGFloat = 12
    static let spacingLarge: CGFloat = 16
    static let spacingXLarge: CGFloat = 24

    static let fontSizeSmall: CGFloat = 12
    static let fontSizeMedium: CGFloat = 14
    static let fontSizeLarge: CGFloat = 16
    static let fontSizeXLarge: CGFloat = 18
    static let fontSizeTitle: CGFloat = 24
}

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

enum ThemeManager {
    static func getColorSet(isDark: Bool) -> ThemeColorSet {
        if isDark {
            return ThemeColorSet(
                primaryColor: Color(red: 0.20, green: 0.65, blue: 1.0),
                primaryColorLight: Color(red: 0.38, green: 0.75, blue: 1.0),
                accentColor: Color(red: 0.35, green: 0.85, blue: 0.72),
                neonPurple: Color(red: 0.72, green: 0.45, blue: 0.98),
                textPrimary: .white,
                textSecondary: Color.white.opacity(0.78),
                textTertiary: Color.white.opacity(0.56),
                backgroundPrimary: Color(red: 0.07, green: 0.08, blue: 0.11),
                backgroundSecondary: Color(red: 0.11, green: 0.13, blue: 0.18),
                backgroundTertiary: Color(red: 0.15, green: 0.18, blue: 0.24),
                borderColor: Color.white.opacity(0.12),
                glowColor: Color(red: 0.20, green: 0.65, blue: 1.0).opacity(0.25),
                successColor: Color(red: 0.33, green: 0.84, blue: 0.48),
                warningColor: Color(red: 1.0, green: 0.72, blue: 0.30),
                errorColor: Color(red: 1.0, green: 0.38, blue: 0.38)
            )
        }

        return ThemeColorSet(
            primaryColor: AppTheme.primaryColor,
            primaryColorLight: AppTheme.primaryColorLight,
            accentColor: Color(red: 0.14, green: 0.64, blue: 0.56),
            neonPurple: Color(red: 0.53, green: 0.36, blue: 0.93),
            textPrimary: AppTheme.textPrimary,
            textSecondary: AppTheme.textSecondary,
            textTertiary: AppTheme.textTertiary,
            backgroundPrimary: AppTheme.backgroundPrimary,
            backgroundSecondary: AppTheme.backgroundSecondary,
            backgroundTertiary: AppTheme.backgroundTertiary,
            borderColor: Color(.separator),
            glowColor: AppTheme.primaryColor.opacity(0.08),
            successColor: AppTheme.successColor,
            warningColor: AppTheme.warningColor,
            errorColor: AppTheme.errorColor
        )
    }
}

final class ThemeSettings: ObservableObject {
    @AppStorage("app_isDarkMode") private var storedDarkMode = false

    var isDarkMode: Bool {
        get { storedDarkMode }
        set {
            objectWillChange.send()
            storedDarkMode = newValue
        }
    }
}
