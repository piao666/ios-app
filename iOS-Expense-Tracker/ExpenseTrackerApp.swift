import SwiftUI
import SwiftData

@main
struct ExpenseTrackerApp: App {
    // 强制注册 S3 阶段的全新模型架构 (包含附件、PDF预留、搜索优化字段)
    let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Transaction.self,
            Category.self
        ])
        
        // 核心配置：关闭纯内存模式确保数据落盘，但强依赖真机层面的旧包卸载
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // 如果你没有卸载旧版本直接覆盖安装，这里会捕获致命的底层结构冲突
            fatalError("海总，底层数据库容器加载致命失败（大概率是旧版数据库未清理导致结构冲突）：\(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // 将全新的数据血脉注入整个 App 视图树
        .modelContainer(sharedModelContainer)
    }
}