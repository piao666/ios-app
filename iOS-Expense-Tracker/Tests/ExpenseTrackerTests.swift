import SwiftData
import XCTest
@testable import ExpenseTracker

final class ExpenseTrackerTests: XCTestCase {
    func testDefaultCategoriesCount() {
        XCTAssertEqual(Category.defaultCategories.count, 9)
    }

    func testDefaultCategoriesContent() {
        let names = Category.defaultCategories.map(\.name)
        let expected = ["餐饮", "交通", "购物", "娱乐", "住房", "医疗", "教育", "工资", "理财"]

        for name in expected {
            XCTAssertTrue(names.contains(name))
        }
    }

    func testTransactionInitialization() {
        let category = Category(name: "测试分类", icon: "star.fill", colorHex: "FF0000", type: .expense)
        let transaction = Transaction(
            amount: 99.99,
            date: Date(),
            note: "测试备注",
            type: .expense,
            category: category
        )

        XCTAssertEqual(transaction.amount, 99.99)
        XCTAssertEqual(transaction.note, "测试备注")
        XCTAssertEqual(transaction.type, .expense)
        XCTAssertEqual(transaction.category.name, "测试分类")
        XCTAssertFalse(transaction.searchKeywords?.isEmpty ?? true)
    }

    func testTransactionInitializationWithoutNote() {
        let category = Category(name: "兼职", icon: "briefcase.fill", colorHex: "00FF00", type: .income)
        let transaction = Transaction(
            amount: 50.0,
            date: Date(),
            type: .income,
            category: category
        )

        XCTAssertEqual(transaction.amount, 50.0)
        XCTAssertNil(transaction.note)
        XCTAssertEqual(transaction.type, .income)
        XCTAssertEqual(transaction.category.name, "兼职")
    }

    func testTransactionTypeCases() {
        XCTAssertEqual(TransactionType.allCases.count, 2)
        XCTAssertTrue(TransactionType.allCases.contains(.income))
        XCTAssertTrue(TransactionType.allCases.contains(.expense))
    }

    func testTransactionTypeRawValues() {
        XCTAssertEqual(TransactionType.income.rawValue, "收入")
        XCTAssertEqual(TransactionType.expense.rawValue, "支出")
    }

    func testGenerateMockData() {
        let categories = Category.defaultCategories
        let transactions = Transaction.generateMockData(using: categories)

        XCTAssertFalse(transactions.isEmpty)
        XCTAssertTrue(transactions.contains { $0.type == .income })
        XCTAssertTrue(transactions.contains { $0.type == .expense })
    }
}
