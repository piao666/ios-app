import Foundation
import SwiftData

@Model
final class Transaction {
    var id: UUID
    var amount: Double
    var title: String
    var note: String?
    var date: Date
    var type: TransactionType
    var category: Category?
    
    init(amount: Double, title: String, note: String? = nil, date: Date = Date(), type: TransactionType, category: Category? = nil) {
        self.id = UUID()
        self.amount = amount
        self.title = title
        self.note = note
        self.date = date
        self.type = type
        self.category = category
    }
}

enum TransactionType: String, Codable, CaseIterable {
    case income = "收入"
    case expense = "支出"
}