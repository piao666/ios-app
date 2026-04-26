import XCTest
@testable import ExpenseTracker

final class ExpenseTrackerTests: XCTestCase {
    func testDefaultCategoriesExist() {
        XCTAssertFalse(Category.defaultCategories.isEmpty)
    }

    func testTransactionSignedAmountTextForExpense() {
        let category = Category.defaultCategories.first ?? Category(
            name: "test",
            icon: "tag.fill",
            colorHex: "2563EB",
            type: .expense,
            sortOrder: 0
        )

        let transaction = Transaction(
            amount: 26,
            date: Date(),
            note: "dinner",
            type: .expense,
            category: category
        )

        XCTAssertTrue(transaction.signedAmountText.hasPrefix("-"))
    }
}
