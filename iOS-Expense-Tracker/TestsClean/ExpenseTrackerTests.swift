import XCTest
@testable import ExpenseTracker

final class ExpenseTrackerTests: XCTestCase {
    func testDefaultCategoriesExist() {
        let categories = Category.defaultCategories

        XCTAssertEqual(categories.count, 7)
        XCTAssertTrue(categories.contains { $0.name == "Food" })
        XCTAssertTrue(categories.contains { $0.name == "Salary" })
    }

    func testTransactionSearchKeywordsContainCoreFields() {
        let category = Category(name: "Travel", icon: "airplane", colorHex: "2563EB", type: .expense)
        let transaction = Transaction(
            amount: 88,
            date: Date(),
            note: "Airport taxi",
            type: .expense,
            category: category
        )

        XCTAssertTrue(transaction.searchKeywords.contains("travel"))
        XCTAssertTrue(transaction.searchKeywords.contains("airport taxi"))
        XCTAssertTrue(transaction.searchKeywords.contains("expense"))
    }

    func testMonthKeyFormatting() {
        var components = DateComponents()
        components.year = 2026
        components.month = 4
        components.day = 10
        let date = Calendar(identifier: .gregorian).date(from: components)!

        XCTAssertEqual(Transaction.monthKey(for: date), "2026-04")
    }

    func testMockDataContainsIncomeAndExpense() {
        let transactions = Transaction.generateMockData(using: Category.defaultCategories)

        XCTAssertFalse(transactions.isEmpty)
        XCTAssertTrue(transactions.contains { $0.type == .income })
        XCTAssertTrue(transactions.contains { $0.type == .expense })
    }
}
