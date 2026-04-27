import Foundation

struct BackupPayload: Codable {
    let schemaVersion: Int
    let exportedAt: Date
    let categories: [CategoryDTO]
    let transactions: [TransactionDTO]

    init(
        schemaVersion: Int = 1,
        exportedAt: Date = Date(),
        categories: [CategoryDTO],
        transactions: [TransactionDTO]
    ) {
        self.schemaVersion = schemaVersion
        self.exportedAt = exportedAt
        self.categories = categories
        self.transactions = transactions
    }
}

struct CategoryDTO: Codable, Identifiable {
    let id: UUID
    let name: String
    let icon: String
    let colorHex: String
    let type: TransactionType
    let sortOrder: Int

    init(category: Category) {
        id = category.id
        name = category.name
        icon = category.icon
        colorHex = category.colorHex
        type = category.type
        sortOrder = category.sortOrder
    }

    func makeModel() -> Category {
        Category(
            id: id,
            name: name,
            icon: icon,
            colorHex: colorHex,
            type: type,
            sortOrder: sortOrder
        )
    }
}

struct TransactionDTO: Codable, Identifiable {
    let id: UUID
    let amount: Double
    let date: Date
    let note: String
    let type: TransactionType
    let categoryID: UUID

    init(transaction: Transaction) {
        id = transaction.id
        amount = transaction.amount
        date = transaction.date
        note = transaction.note
        type = transaction.type
        categoryID = transaction.category.id
    }

    func makeModel(category: Category) -> Transaction {
        Transaction(
            id: id,
            amount: amount,
            date: date,
            note: note,
            type: type,
            category: category
        )
    }
}

extension Category {
    var backupDTO: CategoryDTO {
        CategoryDTO(category: self)
    }

    static func makeModel(from dto: CategoryDTO) -> Category {
        dto.makeModel()
    }
}

extension Transaction {
    var backupDTO: TransactionDTO {
        TransactionDTO(transaction: self)
    }

    static func makeModel(from dto: TransactionDTO, category: Category) -> Transaction {
        dto.makeModel(category: category)
    }
}
