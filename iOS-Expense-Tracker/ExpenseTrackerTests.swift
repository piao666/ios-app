import XCTest
@testable import ExpenseTracker  // 注：根据实际的 iOS 项目 Target 名称调整

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
        // 验证每个默认分类都有有效的 color
        let defaultCategories = Category.defaultCategories

        for category in defaultCategories {
            XCTAssertFalse(category.color.isEmpty, "分类 \(category.name) 应该有有效的 color")
            // 验证颜色格式是否为 hex 格式
            XCTAssertTrue(category.color.hasPrefix("#"), "分类 \(category.name) 的 color 应该以 # 开头")
        }
    }

    // MARK: - Transaction Tests

    func testTransactionInitialization() {
        // 验证 Transaction 初始化是否正确
        let transaction = Transaction(
            amount: 99.99,
            title: "测试交易",
            note: "这是一条测试备注",
            type: .expense
        )

        XCTAssertEqual(transaction.amount, 99.99, "金额应该为 99.99")
        XCTAssertEqual(transaction.title, "测试交易", "标题应该为 '测试交易'")
        XCTAssertEqual(transaction.note, "这是一条测试备注", "备注应该为 '这是一条测试备注'")
        XCTAssertEqual(transaction.type, .expense, "交易类型应该为 expense")
        XCTAssertNotNil(transaction.id, "交易应该有一个有效的 UUID")
    }

    func testTransactionInitializationWithoutNote() {
        // 验证没有 note 的 Transaction 初始化
        let transaction = Transaction(
            amount: 50.0,
            title: "无备注交易",
            type: .income
        )

        XCTAssertEqual(transaction.amount, 50.0)
        XCTAssertEqual(transaction.title, "无备注交易")
        XCTAssertNil(transaction.note, "没有提供 note 时，应该为 nil")
        XCTAssertEqual(transaction.type, .income)
    }

    func testTransactionWithCategory() {
        // 验证带有分类的 Transaction 初始化
        let category = Category(name: "餐饮", icon: "fork.knife", color: "#FF9500")
        let transaction = Transaction(
            amount: 120.50,
            title: "午餐",
            type: .expense,
            category: category
        )

        XCTAssertNotNil(transaction.category, "交易应该有一个分类")
        XCTAssertEqual(transaction.category?.name, "餐饮", "分类名称应该为 '餐饮'")
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
