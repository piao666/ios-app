import SwiftUI
import SwiftData

@main
struct ExpenseTrackerApp: App {
    // MARK: - 全局主题状态（根节点注入，全 App 响应）
    @StateObject private var themeSettings = ThemeSettings()

    // MARK: - SwiftData 容器
    let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Transaction.self,
            Category.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("数据库容器加载失败（可能是旧版数据库结构冲突，请卸载重装）：\(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeSettings)
                // 根节点设置 preferredColorScheme，全 App 所有页面自动响应深色/浅色切换
                .preferredColorScheme(themeSettings.isDarkMode ? .dark : .light)
        }
        .modelContainer(sharedModelContainer)
    }
}