import Charts
import SwiftUI

private struct CategoryExpenseSlice: Identifiable {
    let id: UUID
    let category: Category
    let amount: Double
    let count: Int
}

struct ExpensePieChartView: View {
    @EnvironmentObject private var themeSettings: ThemeSettings

    let transactions: [Transaction]

    private var themeColors: ThemeColorSet {
        ThemeManager.getColorSet(isDark: themeSettings.isDarkMode)
    }

    private var expenseSlices: [CategoryExpenseSlice] {
        let grouped = Dictionary(grouping: transactions.filter { $0.type == .expense }) { $0.category.id }

        return grouped.compactMap { _, items in
            guard let category = items.first?.category else {
                return nil
            }

            return CategoryExpenseSlice(
                id: category.id,
                category: category,
                amount: items.reduce(0) { $0 + $1.amount },
                count: items.count
            )
        }
        .sorted { $0.amount > $1.amount }
    }

    private var totalAmount: Double {
        expenseSlices.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingLarge) {
            Text("支出分类占比")
                .font(.system(size: AppTheme.fontSizeSubtitle, weight: .bold))
                .foregroundStyle(themeColors.textPrimary)

            if expenseSlices.isEmpty {
                emptyState
            } else {
                chartContent
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: AppTheme.spacingSmall) {
            Image(systemName: "chart.pie")
                .font(.system(size: 36))
                .foregroundStyle(themeColors.textTertiary)
            Text("还没有支出数据")
                .font(.system(size: AppTheme.fontSizeBody, weight: .medium))
                .foregroundStyle(themeColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.spacingXXLarge)
        .background(themeColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge)
                .stroke(themeColors.cardBorder, lineWidth: 1)
        )
    }

    private var chartContent: some View {
        VStack(spacing: AppTheme.spacingLarge) {
            Chart(expenseSlices) { slice in
                SectorMark(
                    angle: .value("金额", slice.amount),
                    innerRadius: .ratio(0.56),
                    angularInset: 2
                )
                .foregroundStyle(by: .value("分类", slice.category.name))
            }
            .chartForegroundStyleScale(
                domain: expenseSlices.map { $0.category.name },
                range: expenseSlices.map { $0.category.color }
            )
            .chartLegend(position: .bottom, alignment: .leading, spacing: 8)
            .frame(height: 300)
            .padding(.top, AppTheme.spacingSmall)

            VStack(spacing: AppTheme.spacingSmall) {
                ForEach(expenseSlices) { slice in
                    HStack(spacing: AppTheme.spacingMedium) {
                        Circle()
                            .fill(slice.category.color)
                            .frame(width: 12, height: 12)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(slice.category.name)
                                .font(.system(size: AppTheme.fontSizeBody, weight: .semibold))
                                .foregroundStyle(themeColors.textPrimary)
                            Text("\(slice.count) 笔")
                                .font(.system(size: AppTheme.fontSizeCaption))
                                .foregroundStyle(themeColors.textSecondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(slice.amount, format: .currency(code: "CNY"))
                                .font(.system(size: AppTheme.fontSizeBody, weight: .bold))
                                .foregroundStyle(themeColors.textPrimary)
                            Text(totalAmount == 0 ? "0%" : "\(String(format: "%.1f", slice.amount / totalAmount * 100))%")
                                .font(.system(size: AppTheme.fontSizeCaption))
                                .foregroundStyle(themeColors.textSecondary)
                        }
                    }
                    .padding(AppTheme.spacingMedium)
                    .background(themeColors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)
                            .stroke(themeColors.cardBorder, lineWidth: 1)
                    )
                }
            }
        }
    }
}
