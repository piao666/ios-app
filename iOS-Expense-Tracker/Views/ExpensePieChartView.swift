import SwiftUI
import Charts

struct ExpensePieChartView: View {
    let transactions: [Transaction]

    // 修复：只统计支出，过滤掉收入（工资等），避免统计图严重失真
    var expenseByCategory: [CategoryExpense] {
        let expenseOnly = transactions.filter { $0.type == .expense }
        let grouped = Dictionary(grouping: expenseOnly) { $0.category }
        return grouped.compactMap { category, txs in
            let total = txs.reduce(0) { $0 + $1.amount }
            return CategoryExpense(
                category: category,
                amount: total,
                transactionCount: txs.count
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
                    Text("暂无支出数据")
                        .font(.system(size: AppTheme.fontSizeMedium, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 250)
                .background(AppTheme.primaryColorLight.opacity(0.1))
                .cornerRadius(AppTheme.cornerRadiusLarge)
            } else {
                VStack(spacing: AppTheme.spacingMedium) {
                    // 环形图 + 扇区内百分比标注
                    Chart(expenseByCategory) { item in
                        SectorMark(
                            angle: .value("金额", item.amount),
                            innerRadius: .ratio(0.5),   // 环形图，中间留空
                            angularInset: 2             // 扇区间距
                        )
                        .foregroundStyle(item.category?.color ?? .blue)
                        .opacity(0.88)
                        .annotation(position: .overlay) {
                            // 占比超过 8% 才在扇区内显示百分比，避免文字拥挤
                            if totalAmount > 0 && (item.amount / totalAmount) >= 0.08 {
                                Text("\(Int((item.amount / totalAmount) * 100))%")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .frame(height: 220)

                    // 图例列表
                    VStack(spacing: AppTheme.spacingSmall) {
                        ForEach(expenseByCategory, id: \.id) { item in
                            HStack(spacing: AppTheme.spacingMedium) {
                                HStack(spacing: 6) {
                                    if let category = item.category {
                                        // 颜色色块（与饼图对应）
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(category.color)
                                            .frame(width: 12, height: 12)
                                        Image(systemName: category.icon)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(category.color)
                                            .frame(width: 20)
                                        Text(category.name)
                                            .font(.system(size: AppTheme.fontSizeSmall, weight: .medium))
                                            .foregroundColor(AppTheme.textPrimary)
                                    } else {
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(Color.gray)
                                            .frame(width: 12, height: 12)
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
                                    if totalAmount > 0 {
                                        Text("\(String(format: "%.1f", (item.amount / totalAmount) * 100))%")
                                            .font(.system(size: 10, weight: .regular))
                                            .foregroundColor(AppTheme.textTertiary)
                                    }
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
        ExpensePieChartView(transactions: [
            Transaction(amount: 120.50, date: .now, note: "午餐", type: .expense,
                        category: Category(name: "餐饮", icon: "fork.knife", colorHex: "FF9500", type: .expense)),
            Transaction(amount: 45.00, date: .now, note: "公交", type: .expense,
                        category: Category(name: "交通", icon: "car", colorHex: "5856D6", type: .expense)),
            Transaction(amount: 200.00, date: .now, note: "衣服", type: .expense,
                        category: Category(name: "购物", icon: "bag", colorHex: "FF2D55", type: .expense)),
            Transaction(amount: 80.00, date: .now, note: "电影", type: .expense,
                        category: Category(name: "娱乐", icon: "gamecontroller", colorHex: "AF52DE", type: .expense)),
            // 收入数据不应出现在饼图中（已过滤）
            Transaction(amount: 15000.00, date: .now, note: "工资", type: .income,
                        category: Category(name: "工资", icon: "banknote", colorHex: "4CD964", type: .income)),
        ])
        .padding()
        Spacer()
    }
    .background(AppTheme.backgroundSecondary)
}