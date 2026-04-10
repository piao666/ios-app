import Foundation
import SwiftData
import SwiftUI

enum TransactionType: String, Codable, CaseIterable, Identifiable {
    case expense = "Expense"
    case income = "Income"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .expense:
            return AppTheme.errorColor
        case .income:
            return AppTheme.successColor
        }
    }
}

@Model
final class Category: Identifiable {
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
        Color(hex: colorHex) ?? AppTheme.primaryColor
    }

    static var defaultCategories: [Category] {
        [
            Category(name: "Food", icon: "fork.knife", colorHex: "F97316", type: .expense, sortOrder: 0),
            Category(name: "Transport", icon: "car.fill", colorHex: "2563EB", type: .expense, sortOrder: 1),
            Category(name: "Shopping", icon: "bag.fill", colorHex: "DB2777", type: .expense, sortOrder: 2),
            Category(name: "Home", icon: "house.fill", colorHex: "16A34A", type: .expense, sortOrder: 3),
            Category(name: "Health", icon: "heart.fill", colorHex: "DC2626", type: .expense, sortOrder: 4),
            Category(name: "Salary", icon: "banknote.fill", colorHex: "059669", type: .income, sortOrder: 5),
            Category(name: "Bonus", icon: "gift.fill", colorHex: "7C3AED", type: .income, sortOrder: 6)
        ]
    }
}

@Model
final class Transaction: Identifiable {
    var id: UUID
    var amount: Double
    var date: Date
    var note: String?
    var type: TransactionType
    var category: Category
    var searchKeywords: String
    var yearMonth: String

    init(
        id: UUID = UUID(),
        amount: Double,
        date: Date,
        note: String? = nil,
        type: TransactionType,
        category: Category
    ) {
        self.id = id
        self.amount = amount
        self.date = date
        self.note = note
        self.type = type
        self.category = category
        self.searchKeywords = Transaction.makeSearchKeywords(note: note, categoryName: category.name, type: type.rawValue)
        self.yearMonth = Transaction.monthKey(for: date)
    }

    static func monthKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: date)
    }

    static func makeSearchKeywords(note: String?, categoryName: String, type: String) -> String {
        [categoryName, note ?? "", type]
            .joined(separator: " ")
            .lowercased()
    }

    static func generateMockData(using categories: [Category]) -> [Transaction] {
        guard !categories.isEmpty else {
            return []
        }

        func category(named name: String, type: TransactionType) -> Category {
            categories.first { $0.name == name }
                ?? categories.first { $0.type == type }
                ?? categories[0]
        }

        let calendar = Calendar.current
        let now = Date()
        let breakfast = calendar.date(bySettingHour: 8, minute: 15, second: 0, of: now) ?? now
        let subway = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now) ?? now
        let lunch = calendar.date(bySettingHour: 12, minute: 30, second: 0, of: now) ?? now
        let salaryDate = calendar.date(byAdding: .day, value: -3, to: now) ?? now
        let shoppingDate = calendar.date(byAdding: .day, value: -6, to: now) ?? now
        let bonusDate = calendar.date(byAdding: .day, value: -10, to: now) ?? now

        return [
            Transaction(amount: 12.5, date: breakfast, note: "Breakfast", type: .expense, category: category(named: "Food", type: .expense)),
            Transaction(amount: 4.5, date: subway, note: "Subway", type: .expense, category: category(named: "Transport", type: .expense)),
            Transaction(amount: 21.0, date: lunch, note: "Lunch", type: .expense, category: category(named: "Food", type: .expense)),
            Transaction(amount: 240.0, date: shoppingDate, note: "Weekly shopping", type: .expense, category: category(named: "Shopping", type: .expense)),
            Transaction(amount: 6800.0, date: salaryDate, note: "Monthly salary", type: .income, category: category(named: "Salary", type: .income)),
            Transaction(amount: 800.0, date: bonusDate, note: "Quarterly bonus", type: .income, category: category(named: "Bonus", type: .income))
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
