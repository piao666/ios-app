import SwiftUI
import Charts

struct ExpensePieChartView: View {
    let transactions: [Transaction]

    var expenseByCategory: [CategoryExpense] {
        let grouped = Dictionary(grouping: transactions) { $0.category }
        return grouped.compactMap { category, categoryTransactions in
            let total = categoryTransactions.reduce(0) { $0 + $1.amount }
            return CategoryExpense(
                category: category,
                amount: total,
                transactionCount: categoryTransactions.count
            )
        }
        .sorted { $0.amount > $1.amount }
    }

    var totalAmount: Double {
        expenseByCategory.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        VStack(spacing: AppTheme.spacingLarge) {
            HStack {
                Text("分类消费占比")
                    .font(.system(size: AppTheme.fontSizeMedium, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
            }

            if expenseByCategory.isEmpty {
                VStack(spacing: AppTheme.spacingMedium) {
                    Image(systemName: "chart.pie")
                        .font(.system(size: 48))
                        .foregroundColor(AppTheme.primaryColor.opacity(0.5))
                    Text("暂无消费数据")
                        .font(.system(size: AppTheme.fontSizeMedium, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 250)
                .background(AppTheme.primaryColorLight.opacity(0.1))
                .cornerRadius(AppTheme.cornerRadiusLarge)
            } else {
                VStack(spacing: AppTheme.spacingMedium) {
                    Chart(expenseByCategory) { item in
                        SectorMark(angle: .value("金额", item.amount))
                            .foregroundStyle(item.category?.color ?? .blue) // 使用增强模型的 color 计算属性
                            .opacity(0.85)
                    }
                    .frame(height: 200)

                    VStack(spacing: AppTheme.spacingSmall) {
                        ForEach(expenseByCategory, id: \.id) { item in
                            HStack(spacing: AppTheme.spacingMedium) {
                                HStack(spacing: 6) {
                                    if let category = item.category {
                                        Image(systemName: category.icon)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(category.color)
                                            .frame(width: 24)
                                        Text(category.name)
                                            .font(.system(size: AppTheme.fontSizeSmall, weight: .medium))
                                            .foregroundColor(AppTheme.textPrimary)
                                    } else {
                                        Text("未分类")
                                            .font(.system(size: AppTheme.fontSizeSmall, weight: .medium))
                                            .foregroundColor(AppTheme.textSecondary)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)

                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("¥\(String(format: "%.2f", item.amount))")
                                        .font(.system(size: AppTheme.fontSizeSmall, weight: .semibold))
                                        .foregroundColor(AppTheme.textPrimary)
                                    Text("\(String(format: "%.1f", (item.amount / totalAmount) * 100))%")
                                        .font(.system(size: 10, weight: .regular))
                                        .foregroundColor(AppTheme.textTertiary)
                                }
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, AppTheme.spacingSmall)
                            .background(AppTheme.backgroundSecondary)
                            .cornerRadius(8)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

struct CategoryExpense: Identifiable {
    let id = UUID()
    let category: Category?
    let amount: Double
    let transactionCount: Int
}

#Preview("分类图表 - Mock数据") {
    VStack {
        // 修复：适配增强型初始化构造器
        ExpensePieChartView(transactions: [
            Transaction(amount: 120.50, date: .now, note: "午餐", type: .expense, 
                       category: Category(name: "餐饮", icon: "fork.knife", colorHex: "FF9500", type: .expense)),
            Transaction(amount: 45.00, date: .now, note: "公交", type: .expense, 
                       category: Category(name: "交通", icon: "car", colorHex: "5856D6", type: .expense)),
            Transaction(amount: 200.00, date: .now, note: "衣服", type: .expense, 
                       category: Category(name: "购物", icon: "bag", colorHex: "FF2D55", type: .expense)),
            Transaction(amount: 80.00, date: .now, note: "电影", type: .expense, 
                       category: Category(name: "娱乐", icon: "film", colorHex: "AF52DE", type: .expense)),
        ])
        .padding()
        Spacer()
    }
    .background(AppTheme.backgroundSecondary)
}