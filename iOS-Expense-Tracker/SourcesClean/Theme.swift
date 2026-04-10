import SwiftUI

enum AppTheme {
    static let primaryColor = Color.blue
    static let successColor = Color.green
    static let warningColor = Color.orange
    static let errorColor = Color.red

    static let cardBackground = Color(.secondarySystemBackground)
    static let cardBorder = Color(.separator)
    static let mutedText = Color.secondary

    static let smallSpacing: CGFloat = 8
    static let mediumSpacing: CGFloat = 12
    static let largeSpacing: CGFloat = 16
    static let extraLargeSpacing: CGFloat = 24

    static let smallRadius: CGFloat = 10
    static let mediumRadius: CGFloat = 14
    static let largeRadius: CGFloat = 18
}

@MainActor
final class ThemeSettings: ObservableObject {
    private static let storageKey = "app_isDarkMode"

    @Published var isDarkMode: Bool {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: Self.storageKey)
        }
    }

    init() {
        isDarkMode = UserDefaults.standard.object(forKey: Self.storageKey) as? Bool ?? false
    }
}
