import Foundation
import SwiftData

@Model
final class Category {
    var id: UUID
    var name: String
    var icon: String
    var color: String
    var budget: Double?
    @Relationship(deleteRule: .nullify, inverse: \Transaction.category) var transactions: [Transaction]?
    
    init(name: String, icon: String = "folder", color: String = "#007AFF", budget: Double? = nil) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.color = color
        self.budget = budget
    }
    
    static let defaultCategories: [Category] = [
        Category(name: "餐饮", icon: "fork.knife", color: "#FF9500"),
        Category(name: "交通", icon: "car", color: "#5856D6"),
        Category(name: "购物", icon: "bag", color: "#FF2D55"),
        Category(name: "娱乐", icon: "film", color: "#AF52DE"),
        Category(name: "住房", icon: "house", color: "#34C759"),
        Category(name: "医疗", icon: "heart", color: "#FF3B30"),
        Category(name: "教育", icon: "book", color: "#5AC8FA"),
        Category(name: "收入", icon: "dollarsign.circle", color: "#4CD964"),
    ]
}