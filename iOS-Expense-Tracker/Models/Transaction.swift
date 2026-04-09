import SwiftData
import SwiftUI

@Model
class Transaction {
    // MARK: - 基础字段
    var id: UUID
    var amount: Double
    var date: Date
    var note: String?
    var type: TransactionType

    // MARK: - 分类关联
    var category: Category

    // MARK: - S3 附件支持
    var attachmentPaths: [String]?
    var attachmentData: [Data]?

    // MARK: - PDF 导出预留
    var pdfExportData: Data?
    var pdfExportDate: Date?

    // MARK: - 搜索优化
    var searchKeywords: String?

    // MARK: - 时间轴分组冗余字段
    var yearMonth: String?
    var dayOfWeek: Int?

    // MARK: - 初始化
    init(
        id: UUID = UUID(),
        amount: Double,
        date: Date,
        note: String? = nil,
        type: TransactionType,
        category: Category,
        attachmentPaths: [String]? = nil,
        attachmentData: [Data]? = nil
    ) {
        self.id = id
        self.amount = amount
        self.date = date
        self.note = note
        self.type = type
        self.category = category
        self.attachmentPaths = attachmentPaths
        self.attachmentData = attachmentData
        self.yearMonth = Transaction.formatYearMonth(date)
        self.dayOfWeek = Calendar.current.component(.weekday, from: date)
        self.searchKeywords = "\(category.name) \(note ?? "")".lowercased()
    }

    // MARK: - 辅助方法
    static func formatYearMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: date)
    }

    var hasAttachments: Bool {
        return !(attachmentPaths?.isEmpty ?? true) || !(attachmentData?.isEmpty ?? true)
    }

    var allAttachments: [Any] {
        var attachments: [Any] = []
        if let paths = attachmentPaths { attachments.append(contentsOf: paths) }
        if let data = attachmentData { attachments.append(contentsOf: data) }
        return attachments
    }

    var pdfDescription: String {
        let dateStr = date.formatted(date: .long, time: .shortened)
        let typeStr = type == .expense ? "支出" : "收入"
        return "\(dateStr) - \(typeStr) - \(category.name) - ¥\(String(format: "%.2f", amount))"
    }
}

// MARK: - 交易类型枚举
enum TransactionType: String, Codable, CaseIterable {
    case expense = "支出"
    case income = "收入"

    var color: Color {
        switch self {
        case .expense: return .red
        case .income: return .green
        }
    }

    var icon: String {
        switch self {
        case .expense: return "arrow.down.circle.fill"
        case .income: return "arrow.up.circle.fill"
        }
    }
}

// MARK: - 分类模型
@Model
class Category {
    var id: UUID
    var name: String
    var icon: String
    var colorHex: String
    var type: TransactionType
    var sortOrder: Int

    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        colorHex: String,
        type: TransactionType,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.type = type
        self.sortOrder = sortOrder
    }

    var color: Color {
        Color(hex: colorHex) ?? .blue
    }

    // MARK: - 默认分类（唯一来源，ContentView.onAppear 插入一次）
    static let defaultCategories: [Category] = [
        Category(name: "餐饮",   icon: "fork.knife",          colorHex: "FF9500", type: .expense, sortOrder: 0),
        Category(name: "交通",   icon: "car",                  colorHex: "5856D6", type: .expense, sortOrder: 1),
        Category(name: "购物",   icon: "bag",                  colorHex: "FF2D55", type: .expense, sortOrder: 2),
        Category(name: "娱乐",   icon: "gamecontroller",       colorHex: "AF52DE", type: .expense, sortOrder: 3),
        Category(name: "住房",   icon: "house",                colorHex: "34C759", type: .expense, sortOrder: 4),
        Category(name: "医疗",   icon: "heart",                colorHex: "FF3B30", type: .expense, sortOrder: 5),
        Category(name: "教育",   icon: "book",                 colorHex: "5AC8FA", type: .expense, sortOrder: 6),
        Category(name: "工资",   icon: "banknote",             colorHex: "4CD964", type: .income,  sortOrder: 7),
        Category(name: "理财",   icon: "chart.line.uptrend.xyaxis", colorHex: "FFD93D", type: .income, sortOrder: 8),
    ]
}

// MARK: - 颜色扩展
extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Mock 数据生成
// 关键修复：接收已存在的分类列表，不再自己 new Category，根治设置页分类重复问题
extension Transaction {
    static func generateMockData(using categories: [Category]) -> [Transaction] {
        guard !categories.isEmpty else { return [] }

        let calendar = Calendar.current
        let now = Date()

        // 从已有分类中查找，找不到则回退到第一个
        func cat(_ name: String, fallbackType: TransactionType = .expense) -> Category {
            categories.first { $0.name == name }
                ?? categories.first { $0.type == fallbackType }
                ?? categories[0]
        }

        let food          = cat("餐饮")
        let transport     = cat("交通")
        let shopping      = cat("购物")
        let entertainment = cat("娱乐")
        let salary        = cat("工资", fallbackType: .income)
        let investment    = cat("理财", fallbackType: .income)

        var list: [Transaction] = []

        // 今天
        list.append(Transaction(amount: 25.00,
            date: calendar.date(bySettingHour: 8,  minute: 30, second: 0, of: now)!,
            note: "早餐 - 豆浆油条", type: .expense, category: food))
        list.append(Transaction(amount: 6.00,
            date: calendar.date(bySettingHour: 9,  minute: 15, second: 0, of: now)!,
            note: "上班地铁",         type: .expense, category: transport))
        list.append(Transaction(amount: 45.00,
            date: calendar.date(bySettingHour: 12, minute: 30, second: 0, of: now)!,
            note: "午餐 - 商务套餐",  type: .expense, category: food))

        // 昨天
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        list.append(Transaction(amount: 128.00,
            date: calendar.date(bySettingHour: 19, minute: 30, second: 0, of: yesterday)!,
            note: "晚餐 - 火锅", type: .expense, category: food))
        list.append(Transaction(amount: 35.00,
            date: calendar.date(bySettingHour: 14, minute: 20, second: 0, of: yesterday)!,
            note: "奶茶",         type: .expense, category: food))
        list.append(Transaction(amount: 299.00,
            date: calendar.date(bySettingHour: 20, minute: 15, second: 0, of: yesterday)!,
            note: "买衣服",       type: .expense, category: shopping))
        list.append(Transaction(amount: 15000.00,
            date: calendar.date(bySettingHour: 9,  minute: 0,  second: 0, of: yesterday)!,
            note: "3月工资",      type: .income,  category: salary))

        // 本周其他
        let twoDaysAgo  = calendar.date(byAdding: .day, value: -2, to: now)!
        list.append(Transaction(amount: 68.00,
            date: calendar.date(bySettingHour: 18, minute: 45, second: 0, of: twoDaysAgo)!,
            note: "超市采购", type: .expense, category: shopping))

        let lastSaturday = calendar.date(byAdding: .day, value: -4, to: now)!
        list.append(Transaction(amount: 188.00,
            date: calendar.date(bySettingHour: 15, minute: 30, second: 0, of: lastSaturday)!,
            note: "看电影", type: .expense, category: entertainment))

        let lastSunday = calendar.date(byAdding: .day, value: -3, to: now)!
        list.append(Transaction(amount: 520.00,
            date: calendar.date(bySettingHour: 12, minute: 0,  second: 0, of: lastSunday)!,
            note: "周末聚餐", type: .expense, category: food))

        let lastWednesday = calendar.date(byAdding: .day, value: -6, to: now)!
        list.append(Transaction(amount: 256.00,
            date: calendar.date(bySettingHour: 10, minute: 30, second: 0, of: lastWednesday)!,
            note: "理财收益", type: .income, category: investment))

        let twoWeeksAgo = calendar.date(byAdding: .day, value: -10, to: now)!
        list.append(Transaction(amount: 89.00,
            date: calendar.date(bySettingHour: 16, minute: 20, second: 0, of: twoWeeksAgo)!,
            note: "打车", type: .expense, category: transport))

        return list
    }
}

// MARK: - 预览容器
extension Transaction {
    @MainActor
    static let previewContainer: ModelContainer = {
        do {
            let container = try ModelContainer(
                for: Transaction.self, Category.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            let context = container.mainContext
            let cats = Category.defaultCategories
            cats.forEach { context.insert($0) }
            let mockData = generateMockData(using: cats)
            mockData.forEach { context.insert($0) }
            return container
        } catch {
            fatalError("预览容器创建失败: \(error)")
        }
    }()
}