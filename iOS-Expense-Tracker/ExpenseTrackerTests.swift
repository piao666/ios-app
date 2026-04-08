import XCTest
import SwiftData
@testable import ExpenseTracker 

final class ExpenseTrackerTests: XCTestCase {

    // MARK: - Category Tests

    func testDefaultCategoriesCount() {
        // 验证默认分类列表是否包含 8 个分类
        let defaultCategories = Category.defaultCategories
        XCTAssertEqual(defaultCategories.count, 8, "应该有 8 个默认分类")
    }

    func testDefaultCategoriesContent() {
        // 验证默认分类的具体内容
        let defaultCategories = Category.defaultCategories
        let categoryNames = defaultCategories.map { $0.name }

        let expectedNames = ["餐饮", "交通", "购物", "娱乐", "住房", "医疗", "教育", "收入"]

        for expectedName in expectedNames {
            XCTAssertTrue(categoryNames.contains(expectedName), "应该包含 \(expectedName) 分类")
        }
    }

    func testDefaultCategoriesHaveValidIcons() {
        // 验证每个默认分类都有有效的 icon
        let defaultCategories = Category.defaultCategories

        for category in defaultCategories {
            XCTAssertFalse(category.icon.isEmpty, "分类 \(category.name) 应该有有效的 icon")
        }
    }

    func testDefaultCategoriesHaveValidColors() {
        // 验证每个默认分类都有有效的 colorHex
        let defaultCategories = Category.defaultCategories

        for category in defaultCategories {
            XCTAssertFalse(category.colorHex.isEmpty, "分类 \(category.name) 应该有有效的 colorHex")
        }
    }

    // MARK: - Transaction Tests

    func testTransactionInitialization() {
        // 构造一个有效的 Category 以满足 Transaction 的强类型校验
        let mockCategory = Category(name: "测试分类", icon: "star.fill", colorHex: "FF0000", type: .expense)
        
        let transaction = Transaction(
            amount: 99.99,
            date: Date(),
            note: "这是一条测试备注",
            type: .expense,
            category: mockCategory
        )

        XCTAssertEqual(transaction.amount, 99.99, "金额应该为 99.99")
        XCTAssertNotNil(transaction.date, "交易应该有有效的时间")
        XCTAssertEqual(transaction.note, "这是一条测试备注", "备注应该匹配")
        XCTAssertEqual(transaction.type, .expense, "交易类型应该为 expense")
        XCTAssertEqual(transaction.category.name, "测试分类", "分类名称应该匹配")
        XCTAssertNotNil(transaction.id, "交易应该有一个有效的 UUID")
    }

    func testTransactionInitializationWithoutNote() {
        // 验证没有 note 时的 Transaction 初始化
        let mockCategory = Category(name: "兼职", icon: "briefcase.fill", colorHex: "00FF00", type: .income)
        
        let transaction = Transaction(
            amount: 50.0,
            date: Date(),
            type: .income,
            category: mockCategory
        )

        XCTAssertEqual(transaction.amount, 50.0)
        XCTAssertNil(transaction.note, "没有提供 note 时，应该为 nil")
        XCTAssertEqual(transaction.type, .income)
        XCTAssertEqual(transaction.category.name, "兼职")
    }

    // MARK: - TransactionType Tests

    func testTransactionTypeAllCases() {
        // 验证 TransactionType enum 包含所有预期的 case
        let allCases = TransactionType.allCases

        XCTAssertEqual(allCases.count, 2, "应该有 2 种交易类型")
        XCTAssertTrue(allCases.contains(.income), "应该包含 income 类型")
        XCTAssertTrue(allCases.contains(.expense), "应该包含 expense 类型")
    }

    func testTransactionTypeRawValues() {
        // 验证 TransactionType 的原始值
        XCTAssertEqual(TransactionType.income.rawValue, "收入", "income rawValue 应该为 '收入'")
        XCTAssertEqual(TransactionType.expense.rawValue, "支出", "expense rawValue 应该为 '支出'")
    }
}