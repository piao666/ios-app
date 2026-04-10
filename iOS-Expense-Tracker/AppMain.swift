import SwiftData
import SwiftUI

@main
struct ExpenseTrackerApp: App {
    @StateObject private var themeSettings = ThemeSettings()

    private let sharedModelContainer: ModelContainer = {
        do {
            return try ModelContainer(for: Transaction.self, Category.self)
        } catch {
            fatalError("Failed to create model container: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeSettings)
                .preferredColorScheme(themeSettings.isDarkMode ? .dark : .light)
        }
        .modelContainer(sharedModelContainer)
    }
}
