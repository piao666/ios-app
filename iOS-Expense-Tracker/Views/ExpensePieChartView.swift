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
                    // 饼状图
                    Chart(expenseByCategory) { item in
                        SectorMark(angle: .value("金额", item.amount))
                            .foregroundStyle(Color(hex: item.category?.color ?? "#007AFF"))
                            .opacity(0.85)
                    }
                    .frame(height: 200)

                    // 图例
                    VStack(spacing: AppTheme.spacingSmall) {
                        ForEach(expenseByCategory, id: \.id) { item in
                            HStack(spacing: AppTheme.spacingMedium) {
                                HStack(spacing: 6) {
                                    if let category = item.category {
                                        Image(systemName: category.icon)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(Color(hex: category.color))
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

#Preview {
    VStack {
        ExpensePieChartView(transactions: [
            Transaction(amount: 120.50, title: "午餐", type: .expense, 
                       category: Category(name: "餐饮", icon: "fork.knife", color: "#FF9500")),
            Transaction(amount: 45.00, title: "公交", type: .expense, 
                       category: Category(name: "交通", icon: "car", color: "#5856D6")),
            Transaction(amount: 200.00, title: "衣服", type: .expense, 
                       category: Category(name: "购物", icon: "bag", color: "#FF2D55")),
            Transaction(amount: 80.00, title: "电影", type: .expense, 
                       category: Category(name: "娱乐", icon: "film", color: "#AF52DE")),
        ])
        .padding()
        Spacer()
    }
    .background(AppTheme.backgroundSecondary)
}