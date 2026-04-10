import XCTest
@testable import ExpenseTracker

final class ExpenseTrackerTests: XCTestCase {
    func testDefaultCategoriesContainExpenseAndIncome() {
        let categories = Category.defaultCategories

        XCTAssertTrue(categories.contains(where: { $0.type == .expense }))
        XCTAssertTrue(categories.contains(where: { $0.type == .income }))
    }

    func testMockTransactionsGenerateContent() {
        let categories = Category.defaultCategories
        let transactions = Transaction.generateMockData(using: categories)

        XCTAssertFalse(transactions.isEmpty)
        XCTAssertTrue(transactions.contains(where: { $0.type == .income }))
        XCTAssertTrue(transactions.contains(where: { $0.type == .expense }))
    }
}
