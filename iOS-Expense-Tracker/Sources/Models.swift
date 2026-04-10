import SwiftData
import SwiftUI

enum TransactionType: String, Codable, CaseIterable {
    case expense = "支出"
    case income = "收入"

    var color: Color {
        switch self {
        case .expense:
            return .red
        case .income:
            return .green
        }
    }

    var icon: String {
        switch self {
        case .expense:
            return "arrow.down.circle.fill"
        case .income:
            return "arrow.up.circle.fill"
        }
    }
}

@Model
final class Category {
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

    static var defaultCategories: [Category] {
        [
            Category(name: "餐饮", icon: "fork.knife", colorHex: "FF9500", type: .expense, sortOrder: 0),
            Category(name: "交通", icon: "car", colorHex: "5856D6", type: .expense, sortOrder: 1),
            Category(name: "购物", icon: "bag", colorHex: "FF2D55", type: .expense, sortOrder: 2),
            Category(name: "娱乐", icon: "gamecontroller", colorHex: "AF52DE", type: .expense, sortOrder: 3),
            Category(name: "住房", icon: "house", colorHex: "34C759", type: .expense, sortOrder: 4),
            Category(name: "医疗", icon: "heart", colorHex: "FF3B30", type: .expense, sortOrder: 5),
            Category(name: "教育", icon: "book", colorHex: "5AC8FA", type: .expense, sortOrder: 6),
            Category(name: "工资", icon: "banknote", colorHex: "4CD964", type: .income, sortOrder: 7),
            Category(name: "理财", icon: "chart.line.uptrend.xyaxis", colorHex: "FFD93D", type: .income, sortOrder: 8)
        ]
    }
}

@Model
final class Transaction {
    var id: UUID
    var amount: Double
    var date: Date
    var note: String?
    var type: TransactionType
    var category: Category
    var attachmentPaths: [String]?
    var attachmentData: [Data]?
    var pdfExportData: Data?
    var pdfExportDate: Date?
    var searchKeywords: String?
    var yearMonth: String?
    var dayOfWeek: Int?

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
        self.pdfExportData = nil
        self.pdfExportDate = nil
        self.searchKeywords = Transaction.makeSearchKeywords(note: note, categoryName: category.name, type: type.rawValue)
        self.yearMonth = Transaction.formatYearMonth(date)
        self.dayOfWeek = Calendar.current.component(.weekday, from: date)
    }

    static func formatYearMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: date)
    }

    static func makeSearchKeywords(note: String?, categoryName: String, type: String) -> String {
        [categoryName, note ?? "", type]
            .joined(separator: " ")
            .lowercased()
    }

    var hasAttachments: Bool {
        !(attachmentPaths?.isEmpty ?? true) || !(attachmentData?.isEmpty ?? true)
    }

    var allAttachments: [Any] {
        var attachments: [Any] = []
        if let attachmentPaths {
            attachments.append(contentsOf: attachmentPaths)
        }
        if let attachmentData {
            attachments.append(contentsOf: attachmentData)
        }
        return attachments
    }

    var pdfDescription: String {
        let dateString = date.formatted(date: .long, time: .shortened)
        return "\(dateString) - \(type.rawValue) - \(category.name) - ¥\(String(format: "%.2f", amount))"
    }
}

extension Transaction {
    static func generateMockData(using categories: [Category]) -> [Transaction] {
        guard !categories.isEmpty else {
            return []
        }

        func category(named name: String, fallbackType: TransactionType = .expense) -> Category {
            categories.first { $0.name == name }
                ?? categories.first { $0.type == fallbackType }
                ?? categories[0]
        }

        let now = Date()
        let calendar = Calendar.current

        let food = category(named: "餐饮")
        let transport = category(named: "交通")
        let shopping = category(named: "购物")
        let entertainment = category(named: "娱乐")
        let salary = category(named: "工资", fallbackType: .income)
        let investment = category(named: "理财", fallbackType: .income)

        let todayBreakfast = calendar.date(bySettingHour: 8, minute: 30, second: 0, of: now) ?? now
        let todaySubway = calendar.date(bySettingHour: 9, minute: 15, second: 0, of: now) ?? now
        let todayLunch = calendar.date(bySettingHour: 12, minute: 20, second: 0, of: now) ?? now
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now) ?? now
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: now) ?? now
        let lastWeek = calendar.date(byAdding: .day, value: -7, to: now) ?? now

        return [
            Transaction(amount: 18.0, date: todayBreakfast, note: "早餐", type: .expense, category: food),
            Transaction(amount: 6.0, date: todaySubway, note: "地铁", type: .expense, category: transport),
            Transaction(amount: 42.0, date: todayLunch, note: "午饭", type: .expense, category: food),
            Transaction(
                amount: 168.0,
                date: calendar.date(bySettingHour: 19, minute: 15, second: 0, of: yesterday) ?? yesterday,
                note: "聚餐",
                type: .expense,
                category: food
            ),
            Transaction(
                amount: 259.0,
                date: calendar.date(bySettingHour: 20, minute: 10, second: 0, of: yesterday) ?? yesterday,
                note: "买衣服",
                type: .expense,
                category: shopping
            ),
            Transaction(
                amount: 15000.0,
                date: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: yesterday) ?? yesterday,
                note: "月薪",
                type: .income,
                category: salary
            ),
            Transaction(
                amount: 86.0,
                date: calendar.date(bySettingHour: 18, minute: 30, second: 0, of: twoDaysAgo) ?? twoDaysAgo,
                note: "超市",
                type: .expense,
                category: shopping
            ),
            Transaction(
                amount: 128.0,
                date: calendar.date(bySettingHour: 15, minute: 30, second: 0, of: lastWeek) ?? lastWeek,
                note: "看电影",
                type: .expense,
                category: entertainment
            ),
            Transaction(
                amount: 320.0,
                date: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: lastWeek) ?? lastWeek,
                note: "理财收益",
                type: .income,
                category: investment
            )
        ]
    }
}

extension Transaction {
    @MainActor
    static let previewContainer: ModelContainer = {
        do {
            let container = try ModelContainer(
                for: Transaction.self,
                Category.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            let context = container.mainContext
            let categories = Category.defaultCategories
            categories.forEach { context.insert($0) }
            generateMockData(using: categories).forEach { context.insert($0) }
            return container
        } catch {
            fatalError("Failed to create preview container: \(error)")
        }
    }()
}

extension Color {
    init?(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        guard Scanner(string: cleaned).scanHexInt64(&value) else {
            return nil
        }

        let a: UInt64
        let r: UInt64
        let g: UInt64
        let b: UInt64

        switch cleaned.count {
        case 3:
            (a, r, g, b) = (255, (value >> 8) * 17, (value >> 4 & 0xF) * 17, (value & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, value >> 16, value >> 8 & 0xFF, value & 0xFF)
        case 8:
            (a, r, g, b) = (value >> 24, value >> 16 & 0xFF, value >> 8 & 0xFF, value & 0xFF)
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
