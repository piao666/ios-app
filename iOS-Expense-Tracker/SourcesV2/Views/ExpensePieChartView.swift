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
            guard let category = items.first?.category else { return nil }
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

    private var chartHeight: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        return min(max(screenWidth * 0.62, 220), 300)
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
            // 修复1：移除 chartLegend(position: .bottom)
            // 原因：Swift Charts bottom legend 在 ScrollView 内高度计算失效，
            //       会造成饼图无限扩展并覆盖 TabBar（图1的比例失调问题）
            // 修复2：chartLegend(.hidden) + 固定 frame(height:240)
            Chart(expenseSlices) { slice in
                SectorMark(
                    angle: .value("金额", slice.amount),
                    innerRadius: .ratio(0.56),
                    angularInset: 2
                )
                .foregroundStyle(by: .value("分类", slice.category.name))
                .annotation(position: .overlay) {
                    let pct = totalAmount > 0 ? slice.amount / totalAmount : 0
                    if pct >= 0.01 {
                        Text("\(Int(pct * 100))%")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .chartForegroundStyleScale(
                domain: expenseSlices.map { $0.category.name },
                range: expenseSlices.map { $0.category.color }
            )
            .chartLegend(.hidden)
            .frame(height: chartHeight)
            .padding(.top, AppTheme.spacingSmall)

            // 手动图例：完全可控的高度，显示分类图标+名称+金额+占比
            VStack(spacing: AppTheme.spacingSmall) {
                ForEach(expenseSlices) { slice in
                    HStack(spacing: AppTheme.spacingMedium) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(slice.category.color)
                            .frame(width: 14, height: 14)

                        HStack(spacing: 6) {
                            Image(systemName: slice.category.icon)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(slice.category.color)
                                .frame(width: 18)

                            Text(slice.category.name)
                                .font(.system(size: AppTheme.fontSizeBody, weight: .semibold))
                                .foregroundStyle(themeColors.textPrimary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(slice.amount, format: .currency(code: "CNY"))
                                .font(.system(size: AppTheme.fontSizeBody, weight: .bold))
                                .foregroundStyle(themeColors.textPrimary)

                            Text(
                                totalAmount == 0
                                    ? "0%"
                                    : "\(String(format: "%.1f", slice.amount / totalAmount * 100))% · \(slice.count)笔"
                            )
                            .font(.system(size: AppTheme.fontSizeCaption))
                            .foregroundStyle(themeColors.textSecondary)
                        }
                    }
                    .padding(.horizontal, AppTheme.spacingMedium)
                    .padding(.vertical, 10)
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
