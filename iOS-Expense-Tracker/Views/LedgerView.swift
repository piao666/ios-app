import SwiftUI
import SwiftData

struct LedgerView: View {
    let transactions: [Transaction]

    // 按年月分组的账本数据
    var ledgersByYearMonth: [LedgerGroup] {
        let grouped = Dictionary(grouping: transactions) { transaction -> String in
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM"
            return formatter.string(from: transaction.date)
        }

        return grouped
            .map { yearMonth, txs in
                LedgerGroup(
                    yearMonth: yearMonth,
                    transactions: txs.sorted { $0.date > $1.date }
                )
            }
            .sorted { $0.yearMonth > $1.yearMonth }
    }

    var body: some View {
        if transactions.isEmpty {
            VStack(spacing: AppTheme.spacingMedium) {
                Image(systemName: "book")
                    .font(.system(size: 48))
                    .foregroundColor(AppTheme.primaryColor.opacity(0.5))
                Text("暂无账本数据")
                    .font(.system(size: AppTheme.fontSizeMedium, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.backgroundSecondary)
        } else {
            ScrollView {
                VStack(spacing: AppTheme.spacingMedium) {
                    ForEach(ledgersByYearMonth, id: \.yearMonth) { group in
                        LedgerMonthSection(group: group)
                    }
                }
                .padding(AppTheme.spacingMedium)
            }
        }
    }
}

// MARK: - 按月份分组的账本部分
struct LedgerMonthSection: View {
    let group: LedgerGroup
    @State private var isExpanded = true

    var monthTitle: String {
        if let date = DateFormatter().date(from: group.yearMonth) {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy年MM月"
            return formatter.string(from: date)
        }
        return group.yearMonth
    }

    var monthStats: (income: Double, expense: Double) {
        let income = group.transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
        let expense = group.transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        return (income, expense)
    }

    var body: some View {
        VStack(spacing: 0) {
            // 月份标题和统计
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(monthTitle)
                            .font(.system(size: AppTheme.fontSizeMedium, weight: .semibold))
                            .foregroundColor(AppTheme.textPrimary)
                        HStack(spacing: AppTheme.spacingMedium) {
                            if monthStats.income > 0 {
                                HStack(spacing: 4) {
                                    Text("收入")
                                        .font(.system(size: AppTheme.fontSizeSmall, weight: .medium))
                                        .foregroundColor(AppTheme.successColor)
                                    Text("+¥\(String(format: "%.2f", monthStats.income))")
                                        .font(.system(size: AppTheme.fontSizeSmall, weight: .semibold))
                                        .foregroundColor(AppTheme.successColor)
                                }
                            }
                            if monthStats.expense > 0 {
                                HStack(spacing: 4) {
                                    Text("支出")
                                        .font(.system(size: AppTheme.fontSizeSmall, weight: .medium))
                                        .foregroundColor(AppTheme.errorColor)
                                    Text("-¥\(String(format: "%.2f", monthStats.expense))")
                                        .font(.system(size: AppTheme.fontSizeSmall, weight: .semibold))
                                        .foregroundColor(AppTheme.errorColor)
                                }
                            }
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppTheme.textSecondary)
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
                }
                .padding(AppTheme.spacingMedium)
                .background(AppTheme.backgroundSecondary)
                .cornerRadius(AppTheme.cornerRadiusMedium)
            }

            // 账本内容
            if isExpanded {
                VStack(spacing: AppTheme.spacingSmall) {
                    ForEach(group.transactions, id: \.id) { transaction in
                        LedgerTransactionRow(transaction: transaction)
                    }
                }
                .padding(.top, AppTheme.spacingSmall)
            }
        }
    }
}

// MARK: - 账本交易行
struct LedgerTransactionRow: View {
    let transaction: Transaction

    var typeColor: Color {
        transaction.type == .income ? AppTheme.successColor : AppTheme.errorColor
    }

    var body: some View {
        HStack(spacing: AppTheme.spacingMedium) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: transaction.category.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(transaction.category.color)
                    Text(transaction.category.name)
                        .font(.system(size: AppTheme.fontSizeSmall, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                }
                Text(transaction.note ?? "未命名记录")
                    .font(.system(size: AppTheme.fontSizeMedium, weight: .medium))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(transaction.type == .income ? "+" : "-")¥\(String(format: "%.2f", transaction.amount))")
                    .font(.system(size: AppTheme.fontSizeMedium, weight: .semibold))
                    .foregroundColor(typeColor)
                Text(transaction.date, style: .date)
                    .font(.system(size: AppTheme.fontSizeSmall))
                    .foregroundColor(AppTheme.textTertiary)
            }
        }
        .padding(AppTheme.spacingMedium)
        .background(AppTheme.backgroundSecondary)
        .cornerRadius(AppTheme.cornerRadiusMedium)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)
                .stroke(AppTheme.borderColor, lineWidth: 0.5)
        )
    }
}

// MARK: - 账本数据模型
struct LedgerGroup {
    let yearMonth: String
    let transactions: [Transaction]
}

#Preview("账单簿 - Mock数据") {
    LedgerView(transactions: [
        Transaction(amount: 120.50, date: .now, note: "午餐", type: .expense,
                   category: Category(name: "餐饮", icon: "fork.knife", colorHex: "FF9500", type: .expense)),
        Transaction(amount: 45.00, date: .now, note: "公交", type: .expense,
                   category: Category(name: "交通", icon: "car", colorHex: "5856D6", type: .expense)),
        Transaction(amount: 5000.00, date: Date(timeIntervalSinceNow: -86400*30), note: "工资", type: .income,
                   category: Category(name: "工资", icon: "banknote", colorHex: "4CD964", type: .income)),
    ])
    .background(AppTheme.backgroundPrimary)
}
