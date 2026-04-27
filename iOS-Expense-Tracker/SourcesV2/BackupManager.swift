import Foundation
import SwiftData

enum BackupManager {
    static func exportData(context: ModelContext) throws -> URL {
        let categories = try context.fetch(
            FetchDescriptor<Category>(
                sortBy: [SortDescriptor(\Category.sortOrder)]
            )
        )
        let transactions = try context.fetch(
            FetchDescriptor<Transaction>(
                sortBy: [SortDescriptor(\Transaction.date)]
            )
        )

        let payload = BackupPayload(
            categories: categories.map(\.backupDTO),
            transactions: transactions.map(\.backupDTO)
        )

        let encoder = makeEncoder()
        let data = try encoder.encode(payload)

        let fileName = "xiaohai-backup-\(timestampString()).json"
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(fileName)

        do {
            try data.write(to: fileURL, options: .atomic)
            return fileURL
        } catch {
            throw BackupError.writeFailed(underlyingError: error)
        }
    }

    static func importData(from url: URL, context: ModelContext) throws {
        let hasScopedAccess = url.startAccessingSecurityScopedResource()
        defer {
            if hasScopedAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw BackupError.readFailed(underlyingError: error)
        }

        let payload: BackupPayload
        do {
            payload = try makeDecoder().decode(BackupPayload.self, from: data)
        } catch {
            throw BackupError.decodeFailed(underlyingError: error)
        }

        try validateNoDuplicateIDs(in: payload)

        let existingCategories = try context.fetch(FetchDescriptor<Category>())
        let existingTransactions = try context.fetch(FetchDescriptor<Transaction>())

        var categoriesByID = Dictionary(uniqueKeysWithValues: existingCategories.map { ($0.id, $0) })
        var existingTransactionIDs = Set(existingTransactions.map(\.id))
        let availableCategoryIDs = Set(categoriesByID.keys).union(payload.categories.map(\.id))
        let missingCategoryIDs = Set(payload.transactions.map(\.categoryID)).subtracting(availableCategoryIDs)

        guard missingCategoryIDs.isEmpty else {
            throw BackupError.missingCategoryReference(ids: Array(missingCategoryIDs))
        }

        for categoryDTO in payload.categories where categoriesByID[categoryDTO.id] == nil {
            let category = Category.makeModel(from: categoryDTO)
            context.insert(category)
            categoriesByID[category.id] = category
        }

        for transactionDTO in payload.transactions {
            guard existingTransactionIDs.insert(transactionDTO.id).inserted else {
                continue
            }

            guard let category = categoriesByID[transactionDTO.categoryID] else {
                throw BackupError.missingCategoryReference(ids: [transactionDTO.categoryID])
            }

            let transaction = Transaction.makeModel(from: transactionDTO, category: category)
            context.insert(transaction)
        }

        do {
            try context.save()
        } catch {
            throw BackupError.saveFailed(underlyingError: error)
        }
    }

    private static func validateNoDuplicateIDs(in payload: BackupPayload) throws {
        let categoryIDs = payload.categories.map(\.id)
        if Set(categoryIDs).count != categoryIDs.count {
            throw BackupError.duplicateIdentifiers(entityName: "Category")
        }

        let transactionIDs = payload.transactions.map(\.id)
        if Set(transactionIDs).count != transactionIDs.count {
            throw BackupError.duplicateIdentifiers(entityName: "Transaction")
        }
    }

    private static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    private static func timestampString() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter.string(from: Date())
    }
}

enum BackupError: LocalizedError {
    case readFailed(underlyingError: Error)
    case writeFailed(underlyingError: Error)
    case decodeFailed(underlyingError: Error)
    case saveFailed(underlyingError: Error)
    case duplicateIdentifiers(entityName: String)
    case missingCategoryReference(ids: [UUID])

    var errorDescription: String? {
        switch self {
        case .readFailed(let underlyingError):
            return "无法读取备份文件：\(underlyingError.localizedDescription)"
        case .writeFailed(let underlyingError):
            return "无法写入备份文件：\(underlyingError.localizedDescription)"
        case .decodeFailed(let underlyingError):
            return "备份文件格式无效：\(underlyingError.localizedDescription)"
        case .saveFailed(let underlyingError):
            return "导入后保存失败：\(underlyingError.localizedDescription)"
        case .duplicateIdentifiers(let entityName):
            return "备份文件中存在重复的 \(entityName) 标识，已停止导入。"
        case .missingCategoryReference(let ids):
            let idList = ids.map(\.uuidString).joined(separator: ", ")
            return "备份文件中存在缺失的分类引用：\(idList)"
        }
    }
}
