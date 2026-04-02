//
//  Transaction.swift
//  iOS记账应用 - S3阶段增强版数据模型
//  支持时间轴分组、图片附件、PDF导出预留
//

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
    
    // MARK: - S3阶段新增字段
    // 图片附件支持
    var attachmentPaths: [String]?  // 本地图片路径数组
    var attachmentData: [Data]?     // 图片数据（可选）
    
    // PDF导出预留字段
    var pdfExportData: Data?        // PDF导出数据缓存
    var pdfExportDate: Date?        // 最后PDF导出时间
    
    // 搜索优化字段
    var searchKeywords: String?     // 预计算的搜索关键词
    
    // 时间轴分组优化（冗余字段，提升查询性能）
    var yearMonth: String?          // "2026-04" 格式，用于月度分组
    var dayOfWeek: Int?             // 1-7，星期几
    
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
        
        // 预计算时间轴分组字段
        self.yearMonth = Transaction.formatYearMonth(date)
        self.dayOfWeek = Calendar.current.component(.weekday, from: date)
        
        // 预计算搜索关键词
        self.searchKeywords = "\(category.name) \(note ?? "")".lowercased()
    }
    
    // MARK: - 辅助方法
    
    /// 格式化年月字符串
    static func formatYearMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: date)
    }
    
    /// 检查交易是否包含附件
    var hasAttachments: Bool {
        return !(attachmentPaths?.isEmpty ?? true) || !(attachmentData?.isEmpty ?? true)
    }
    
    /// 获取所有附件（路径或数据）
    var allAttachments: [Any] {
        var attachments: [Any] = []
        if let paths = attachmentPaths { attachments.append(contentsOf: paths) }
        if let data = attachmentData { attachments.append(contentsOf: data) }
        return attachments
    }
    
    /// 为PDF导出准备的数据描述
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
    
    // 排序权重
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
    
    /// 颜色转换
    var color: Color {
        Color(hex: colorHex) ?? .blue
    }
}

// MARK: - 颜色扩展
extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
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

// MARK: - Mock数据生成
extension Transaction {
    /// 生成Mock测试数据（包含今天、昨天、跨周日期的交易）
    static func generateMockData() -> [Transaction] {
        let calendar = Calendar.current
        let now = Date()
        
        // 创建分类
        let food = Category(name: "餐饮", icon: "fork.knife", colorHex: "FF6B6B", type: .expense, sortOrder: 0)
        let transport = Category(name: "交通", icon: "car.fill", colorHex: "4ECDC4", type: .expense, sortOrder: 1)
        let shopping = Category(name: "购物", icon: "bag.fill", colorHex: "45B7D1", type: .expense, sortOrder: 2)
        let entertainment = Category(name: "娱乐", icon: "gamecontroller.fill", colorHex: "96CEB4", type: .expense, sortOrder: 3)
        let salary = Category(name: "工资", icon: "banknote.fill", colorHex: "51CF66", type: .income, sortOrder: 0)
        let investment = Category(name: "理财", icon: "chart.line.uptrend.xyaxis", colorHex: "FFD93D", type: .income, sortOrder: 1)
        
        var transactions: [Transaction] = []
        
        // MARK: - 今天的交易（3笔）
        // 早餐
        transactions.append(Transaction(
            amount: 25.00,
            date: calendar.date(bySettingHour: 8, minute: 30, second: 0, of: now)!,
            note: "早餐 - 豆浆油条",
            type: .expense,
            category: food
        ))
        
        // 地铁
        transactions.append(Transaction(
            amount: 6.00,
            date: calendar.date(bySettingHour: 9, minute: 15, second: 0, of: now)!,
            note: "上班地铁",
            type: .expense,
            category: transport
        ))
        
        // 午餐
        transactions.append(Transaction(
            amount: 45.00,
            date: calendar.date(bySettingHour: 12, minute: 30, second: 0, of: now)!,
            note: "午餐 - 商务套餐",
            type: .expense,
            category: food
        ))
        
        // MARK: - 昨天的交易（4笔）
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        
        transactions.append(Transaction(
            amount: 128.00,
            date: calendar.date(bySettingHour: 19, minute: 30, second: 0, of: yesterday)!,
            note: "晚餐 - 火锅",
            type: .expense,
            category: food
        ))
        
        transactions.append(Transaction(
            amount: 35.00,
            date: calendar.date(bySettingHour: 14, minute: 20, second: 0, of: yesterday)!,
            note: "奶茶",
            type: .expense,
            category: food
        ))
        
        transactions.append(Transaction(
            amount: 299.00,
            date: calendar.date(bySettingHour: 20, minute: 15, second: 0, of: yesterday)!,
            note: "买衣服",
            type: .expense,
            category: shopping
        ))
        
        transactions.append(Transaction(
            amount: 15000.00,
            date: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: yesterday)!,
            note: "3月工资",
            type: .income,
            category: salary
        ))
        
        // MARK: - 本周其他日期的交易
        // 前天（周一）
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: now)!
        transactions.append(Transaction(
            amount: 68.00,
            date: calendar.date(bySettingHour: 18, minute: 45, second: 0, of: twoDaysAgo)!,
            note: "超市采购",
            type: .expense,
            category: shopping
        ))
        
        // 上周六
        let lastSaturday = calendar.date(byAdding: .day, value: -4, to: now)!
        transactions.append(Transaction(
            amount: 188.00,
            date: calendar.date(bySettingHour: 15, minute: 30, second: 0, of: lastSaturday)!,
            note: "看电影",
            type: .expense,
            category: entertainment
        ))
        
        // 上周日
        let lastSunday = calendar.date(byAdding: .day, value: -3, to: now)!
        transactions.append(Transaction(
            amount: 520.00,
            date: calendar.date(bySettingHour: 12, minute: 0, second: 0, of: lastSunday)!,
            note: "周末聚餐",
            type: .expense,
            category: food
        ))
        
        // 上周三
        let lastWednesday = calendar.date(byAdding: .day, value: -6, to: now)!
        transactions.append(Transaction(
            amount: 256.00,
            date: calendar.date(bySettingHour: 10, minute: 30, second: 0, of: lastWednesday)!,
            note: "理财收益",
            type: .income,
            category: investment
        ))
        
        // 上上周
        let twoWeeksAgo = calendar.date(byAdding: .day, value: -10, to: now)!
        transactions.append(Transaction(
            amount: 89.00,
            date: calendar.date(bySettingHour: 16, minute: 20, second: 0, of: twoWeeksAgo)!,
            note: "打车",
            type: .expense,
            category: transport
        ))
        
        return transactions
    }
}

// MARK: - 预览数据
extension Transaction {
    /// 用于Xcode预览的Mock数据容器
    @MainActor
    static let previewContainer: ModelContainer = {
        do {
            let container = try ModelContainer(
                for: Transaction.self, Category.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            
            // 插入Mock数据
            let context = container.mainContext
            let mockData = generateMockData()
            mockData.forEach { context.insert($0) }
            
            return container
        } catch {
            fatalError("Failed to create preview container: \(error)")
        }
    }()
}