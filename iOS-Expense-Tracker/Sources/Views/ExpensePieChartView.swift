import Charts
import SwiftUI

struct ExpensePieChartView: View {
    let transactions: [Transaction]

    var expenseByCategory: [CategoryExpense] {
        let expenses = transactions.filter { $0.type == .expense }
        let grouped = Dictionary(grouping: expenses) { $0.category.id }

        return grouped.compactMap { _, items in
            guard let first = items.first else {
                return nil
            }

            return CategoryExpense(
                category: first.category,
                amount: items.reduce(0) { $0 + $1.amount },
                transactionCount: items.count
            )
        }
        .sorted { $0.amount > $1.amount }
    }

    var totalAmount: Double {
        expenseByCategory.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingLarge) {
            Text("分类支出占比")
                .font(.system(size: AppTheme.fontSizeMedium, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)

            if expenseByCategory.isEmpty {
                VStack(spacing: AppTheme.spacingMedium) {
                    Image(systemName: "chart.pie")
                        .font(.system(size: 48))
                        .foregroundStyle(AppTheme.textTertiary)
                    Text("暂无支出数据")
                        .font(.system(size: AppTheme.fontSizeMedium, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 240)
                .background(AppTheme.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge))
            } else {
                Chart(expenseByCategory) { item in
                    SectorMark(
                        angle: .value("金额", item.amount),
                        innerRadius: .ratio(0.55),
                        angularInset: 2
                    )
                    .foregroundStyle(item.category.color)
                    .annotation(position: .overlay) {
                        if totalAmount > 0, item.amount / totalAmount >= 0.08 {
                            Text("\(Int((item.amount / totalAmount) * 100))%")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .frame(height: 220)

                VStack(spacing: AppTheme.spacingSmall) {
                    ForEach(expenseByCategory) { item in
                        HStack(spacing: AppTheme.spacingMedium) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(item.category.color)
                                .frame(width: 12, height: 12)

                            Image(systemName: item.category.icon)
                                .foregroundStyle(item.category.color)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.category.name)
                                    .font(.subheadline.weight(.medium))
                                Text("\(item.transactionCount) 笔")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text(item.amount, format: .currency(code: "CNY"))
                                    .font(.subheadline.weight(.semibold))
                                Text(totalAmount == 0 ? "0%" : "\(String(format: "%.1f", item.amount / totalAmount * 100))%")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal, AppTheme.spacingMedium)
                        .padding(.vertical, 10)
                        .background(AppTheme.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium))
                    }
                }
            }
        }
    }
}

struct CategoryExpense: Identifiable {
    let id = UUID()
    let category: Category
    let amount: Double
    let transactionCount: Int
}

#Preview {
    ExpensePieChartView(transactions: Transaction.generateMockData(using: Category.defaultCategories))
        .padding()
}
