import SwiftUI

enum AppTheme {
    static let primaryColor = Color(red: 0.08, green: 0.48, blue: 0.95)
    static let primarySoftColor = Color(red: 0.52, green: 0.76, blue: 1.0)
    static let accentColor = Color(red: 0.03, green: 0.74, blue: 0.65)
    static let successColor = Color(red: 0.16, green: 0.69, blue: 0.36)
    static let warningColor = Color(red: 0.95, green: 0.59, blue: 0.20)
    static let errorColor = Color(red: 0.92, green: 0.27, blue: 0.30)

    static let spacingXSmall: CGFloat = 6
    static let spacingSmall: CGFloat = 10
    static let spacingMedium: CGFloat = 14
    static let spacingLarge: CGFloat = 18
    static let spacingXLarge: CGFloat = 24
    static let spacingXXLarge: CGFloat = 32

    static let cornerRadiusSmall: CGFloat = 12
    static let cornerRadiusMedium: CGFloat = 18
    static let cornerRadiusLarge: CGFloat = 26

    static let fontSizeCaption: CGFloat = 13
    static let fontSizeBody: CGFloat = 16
    static let fontSizeSubtitle: CGFloat = 20
    static let fontSizeTitle: CGFloat = 32
    static let fontSizeHero: CGFloat = 34
}

struct ThemeColorSet {
    let primaryColor: Color
    let primarySoftColor: Color
    let accentColor: Color
    let successColor: Color
    let warningColor: Color
    let errorColor: Color
    let textPrimary: Color
    let textSecondary: Color
    let textTertiary: Color
    let backgroundPrimary: Color
    let backgroundSecondary: Color
    let cardBackground: Color
    let cardBorder: Color
    let heroTopColor: Color
    let heroBottomColor: Color
    let chipBackground: Color
    let shadowColor: Color
}

enum ThemeManager {
    static func getColorSet(isDark: Bool) -> ThemeColorSet {
        if isDark {
            return ThemeColorSet(
                primaryColor: Color(red: 0.34, green: 0.73, blue: 1.0),
                primarySoftColor: Color(red: 0.57, green: 0.84, blue: 1.0),
                accentColor: Color(red: 0.31, green: 0.89, blue: 0.77),
                successColor: Color(red: 0.30, green: 0.86, blue: 0.50),
                warningColor: Color(red: 1.0, green: 0.73, blue: 0.27),
                errorColor: Color(red: 1.0, green: 0.43, blue: 0.46),
                textPrimary: Color.white,
                textSecondary: Color.white.opacity(0.78),
                textTertiary: Color.white.opacity(0.55),
                backgroundPrimary: Color(red: 0.04, green: 0.06, blue: 0.10),
                backgroundSecondary: Color(red: 0.08, green: 0.11, blue: 0.17),
                cardBackground: Color(red: 0.10, green: 0.14, blue: 0.21),
                cardBorder: Color.white.opacity(0.08),
                heroTopColor: Color(red: 0.10, green: 0.18, blue: 0.30),
                heroBottomColor: Color(red: 0.06, green: 0.10, blue: 0.18),
                chipBackground: Color.white.opacity(0.08),
                shadowColor: Color.black.opacity(0.24)
            )
        }

        return ThemeColorSet(
            primaryColor: AppTheme.primaryColor,
            primarySoftColor: AppTheme.primarySoftColor,
            accentColor: AppTheme.accentColor,
            successColor: AppTheme.successColor,
            warningColor: AppTheme.warningColor,
            errorColor: AppTheme.errorColor,
            textPrimary: Color(red: 0.08, green: 0.11, blue: 0.16),
            textSecondary: Color(red: 0.37, green: 0.42, blue: 0.49),
            textTertiary: Color(red: 0.58, green: 0.62, blue: 0.69),
            backgroundPrimary: Color(red: 0.96, green: 0.97, blue: 0.99),
            backgroundSecondary: Color.white,
            cardBackground: Color.white,
            cardBorder: Color.black.opacity(0.05),
            heroTopColor: Color(red: 0.92, green: 0.96, blue: 1.0),
            heroBottomColor: Color(red: 0.85, green: 0.93, blue: 1.0),
            chipBackground: Color(red: 0.93, green: 0.95, blue: 0.98),
            shadowColor: Color(red: 0.16, green: 0.24, blue: 0.35).opacity(0.10)
        )
    }
}

final class ThemeSettings: ObservableObject {
    @AppStorage("app.isDarkMode") var isDarkMode: Bool = false

    func toggle() {
        isDarkMode.toggle()
    }
}
