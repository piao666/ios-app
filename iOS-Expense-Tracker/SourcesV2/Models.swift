import Foundation
import SwiftData
import SwiftUI

enum TransactionType: String, Codable, CaseIterable, Identifiable {
    case expense = "支出"
    case income = "收入"

    var id: Self { self }

    var color: Color {
        switch self {
        case .expense:
            return AppTheme.errorColor
        case .income:
            return AppTheme.successColor
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

enum InputTabType: String, CaseIterable, Identifiable {
    case voice
    case text

    var id: Self { self }

    var title: String {
        switch self {
        case .voice:
            return "语音记账"
        case .text:
            return "手动记账"
        }
    }

    var icon: String {
        switch self {
        case .voice:
            return "waveform"
        case .text:
            return "square.and.pencil"
        }
    }
}

enum TransactionFilter: String, CaseIterable, Identifiable {
    case all
    case expense
    case income
    case today
    case week
    case month

    var id: Self { self }

    var title: String {
        switch self {
        case .all:
            return "全部"
        case .expense:
            return "支出"
        case .income:
            return "收入"
        case .today:
            return "今天"
        case .week:
            return "近7天"
        case .month:
            return "近30天"
        }
    }

    func includes(_ transaction: Transaction, now: Date = Date()) -> Bool {
        let calendar = Calendar.current

        switch self {
        case .all:
            return true
        case .expense:
            return transaction.type == .expense
        case .income:
            return transaction.type == .income
        case .today:
            return calendar.isDate(transaction.date, inSameDayAs: now)
        case .week:
            guard let startDate = calendar.date(byAdding: .day, value: -7, to: now) else {
                return true
            }
            return transaction.date >= startDate
        case .month:
            guard let startDate = calendar.date(byAdding: .day, value: -30, to: now) else {
                return true
            }
            return transaction.date >= startDate
        }
    }
}

@Model
final class Category {
    var id: UUID
    var name: String
    var icon: String
    var colorHex: String
    var typeRawValue: String
    var sortOrder: Int

    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        colorHex: String,
        type: TransactionType,
        sortOrder: Int
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.typeRawValue = type.rawValue
        self.sortOrder = sortOrder
    }

    var type: TransactionType {
        get { TransactionType(rawValue: typeRawValue) ?? .expense }
        set { typeRawValue = newValue.rawValue }
    }

    var color: Color {
        Color(hex: colorHex) ?? AppTheme.primaryColor
    }

    static let defaultCategories: [Category] = [
        Category(name: "餐饮", icon: "fork.knife", colorHex: "F97316", type: .expense, sortOrder: 0),
        Category(name: "交通", icon: "car.fill", colorHex: "2563EB", type: .expense, sortOrder: 1),
        Category(name: "购物", icon: "bag.fill", colorHex: "DB2777", type: .expense, sortOrder: 2),
        Category(name: "娱乐", icon: "gamecontroller.fill", colorHex: "8B5CF6", type: .expense, sortOrder: 3),
        Category(name: "住房", icon: "house.fill", colorHex: "16A34A", type: .expense, sortOrder: 4),
        Category(name: "医疗", icon: "cross.case.fill", colorHex: "DC2626", type: .expense, sortOrder: 5),
        Category(name: "教育", icon: "book.fill", colorHex: "0EA5E9", type: .expense, sortOrder: 6),
        Category(name: "工资", icon: "banknote.fill", colorHex: "059669", type: .income, sortOrder: 7),
        Category(name: "理财", icon: "chart.line.uptrend.xyaxis", colorHex: "D97706", type: .income, sortOrder: 8)
    ]
}

@Model
final class Transaction {
    var id: UUID
    var amount: Double
    var date: Date
    var note: String
    var typeRawValue: String
    var category: Category
    var searchText: String
    var yearMonth: String

    init(
        id: UUID = UUID(),
        amount: Double,
        date: Date,
        note: String = "",
        type: TransactionType,
        category: Category
    ) {
        self.id = id
        self.amount = amount
        self.date = date
        self.note = note
        self.typeRawValue = type.rawValue
        self.category = category
        self.searchText = Transaction.makeSearchText(note: note, categoryName: category.name, type: type.rawValue)
        self.yearMonth = Transaction.formatYearMonth(date)
    }

    var type: TransactionType {
        get { TransactionType(rawValue: typeRawValue) ?? .expense }
        set {
            typeRawValue = newValue.rawValue
            searchText = Transaction.makeSearchText(note: note, categoryName: category.name, type: newValue.rawValue)
        }
    }

    var displayTitle: String {
        note.isEmpty ? category.name : note
    }

    var signedAmountText: String {
        let prefix = type == .income ? "+" : "-"
        return prefix + amount.formatted(.currency(code: "CNY"))
    }

    static func formatYearMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: date)
    }

    static func makeSearchText(note: String, categoryName: String, type: String) -> String {
        [note, categoryName, type]
            .joined(separator: " ")
            .lowercased()
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

        let calendar = Calendar.current
        let now = Date()
        let breakfast = calendar.date(bySettingHour: 8, minute: 15, second: 0, of: now) ?? now
        let subway = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now) ?? now
        let lunch = calendar.date(bySettingHour: 12, minute: 30, second: 0, of: now) ?? now
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now) ?? now
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: now) ?? now
        let lastWeek = calendar.date(byAdding: .day, value: -7, to: now) ?? now

        return [
            Transaction(amount: 12.5, date: breakfast, note: "早餐 豆浆油条", type: .expense, category: category(named: "餐饮")),
            Transaction(amount: 4.5, date: subway, note: "早高峰地铁", type: .expense, category: category(named: "交通")),
            Transaction(amount: 21, date: lunch, note: "午餐 简餐", type: .expense, category: category(named: "餐饮")),
            Transaction(amount: 169, date: yesterday, note: "超市采购", type: .expense, category: category(named: "购物")),
            Transaction(amount: 58, date: threeDaysAgo, note: "电影票", type: .expense, category: category(named: "娱乐")),
            Transaction(amount: 6800, date: threeDaysAgo, note: "四月工资", type: .income, category: category(named: "工资", fallbackType: .income)),
            Transaction(amount: 320, date: lastWeek, note: "基金止盈", type: .income, category: category(named: "理财", fallbackType: .income))
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
            fatalError("无法创建预览数据：\(error)")
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

        guard cleaned.count == 6 else {
            return nil
        }

        let red = Double(value >> 16) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue = Double(value & 0xFF) / 255
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: 1)
    }
}
