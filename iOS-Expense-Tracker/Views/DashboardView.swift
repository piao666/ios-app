import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query private var transactions: [Transaction]

    var currentMonthTransactions: [Transaction] {
        let now = Date()
        let calendar = Calendar.current
        let currentMonth = calendar.dateComponents([.month, .year], from: now)

        return transactions.filter { transaction in
            let transactionDate = calendar.dateComponents([.month, .year], from: transaction.date)
            return transactionDate.month == currentMonth.month && transactionDate.year == currentMonth.year && transaction.type == .expense
        }
    }

    var totalExpense: Double {
        currentMonthTransactions.reduce(0) { $0 + $1.amount }
    }

    var currentMonthString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY年MM月"
        return formatter.string(from: Date())
    }

    var body: some View {
        ZStack {
            // 背景
            AppTheme.backgroundSecondary.ignoresSafeArea()

            VStack(spacing: AppTheme.spacingXLarge) {
                // 顶部月份显示
                VStack(alignment: .leading, spacing: AppTheme.spacingSmall) {
                    Text("概览")
                        .font(.system(size: AppTheme.fontSizeTitle, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)

                    Text(currentMonthString)
                        .font(.system(size: AppTheme.fontSizeLarge, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AppTheme.spacingLarge)
                .padding(.top, AppTheme.spacingMedium)

                // 本月总支出卡片
                VStack(spacing: AppTheme.spacingMedium) {
                    HStack {
                        VStack(alignment: .leading, spacing: AppTheme.spacingSmall) {
                            Text("本月总支出")
                                .font(.system(size: AppTheme.fontSizeMedium, weight: .medium))
                                .foregroundColor(AppTheme.textSecondary)

                            Text("¥\(String(format: "%.2f", totalExpense))")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(AppTheme.primaryColor)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: AppTheme.spacingSmall) {
                            Text("交易笔数")
                                .font(.system(size: AppTheme.fontSizeMedium, weight: .medium))
                                .foregroundColor(AppTheme.textSecondary)

                            Text("\(currentMonthTransactions.count)")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)
                        }
                    }
                    .padding(AppTheme.spacingLarge)
                }
                .background(AppTheme.backgroundPrimary)
                .cornerRadius(AppTheme.cornerRadiusLarge)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                .padding(.horizontal, AppTheme.spacingLarge)

                // 占位符 - 消费占比可视化
                VStack(spacing: AppTheme.spacingMedium) {
                    HStack {
                        Text("分类消费占比")
                            .font(.system(size: AppTheme.fontSizeMedium, weight: .semibold))
                            .foregroundColor(AppTheme.textPrimary)

                        Spacer()
                    }

                    // 可视化占位符
                    ZStack {
                        AppTheme.primaryColorLight.opacity(0.1)

                        VStack(spacing: AppTheme.spacingMedium) {
                            Image(systemName: "chart.pie")
                                .font(.system(size: 48))
                                .foregroundColor(AppTheme.primaryColor.opacity(0.5))

                            Text("图表展示位置")
                                .font(.system(size: AppTheme.fontSizeMedium, weight: .medium))
                                .foregroundColor(AppTheme.textSecondary)

                            Text("敬请期待详细的消费分析数据")
                                .font(.system(size: AppTheme.fontSizeSmall))
                                .foregroundColor(AppTheme.textTertiary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .frame(height: 200)
                    .cornerRadius(AppTheme.cornerRadiusLarge)
                }
                .padding(.horizontal, AppTheme.spacingLarge)

                Spacer()
            }
            .padding(.vertical, AppTheme.spacingLarge)
        }
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [Transaction.self, Category.self], inMemory: true)
}
