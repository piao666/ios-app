import SwiftUI

struct LedgerView: View {
    let transactions: [Transaction]

    private var ledgersByYearMonth: [LedgerGroup] {
        let grouped = Dictionary(grouping: transactions) { transaction in
            Transaction.formatYearMonth(transaction.date)
        }

        return grouped
            .map { yearMonth, items in
                LedgerGroup(
                    yearMonth: yearMonth,
                    transactions: items.sorted { $0.date > $1.date }
                )
            }
            .sorted { $0.yearMonth > $1.yearMonth }
    }

    var body: some View {
        if transactions.isEmpty {
            VStack(spacing: AppTheme.spacingMedium) {
                Image(systemName: "book")
                    .font(.system(size: 48))
                    .foregroundStyle(AppTheme.primaryColor.opacity(0.5))
                Text("暂无账本数据")
                    .font(.headline)
                    .foregroundStyle(AppTheme.textSecondary)
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

struct LedgerMonthSection: View {
    let group: LedgerGroup
    @State private var isExpanded = true

    private var monthTitle: String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM"

        guard let date = inputFormatter.date(from: group.yearMonth) else {
            return group.yearMonth
        }

        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "yyyy年M月"
        return outputFormatter.string(from: date)
    }

    private var monthStats: (income: Double, expense: Double) {
        let income = group.transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
        let expense = group.transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        return (income, expense)
    }

    var body: some View {
        VStack(spacing: AppTheme.spacingSmall) {
            Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(monthTitle)
                            .font(.headline)
                            .foregroundStyle(AppTheme.textPrimary)

                        HStack(spacing: AppTheme.spacingMedium) {
                            if monthStats.income > 0 {
                                Text("收入 +¥\(String(format: "%.2f", monthStats.income))")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.successColor)
                            }

                            if monthStats.expense > 0 {
                                Text("支出 -¥\(String(format: "%.2f", monthStats.expense))")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.errorColor)
                            }
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(AppTheme.spacingMedium)
                .background(AppTheme.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium))
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: AppTheme.spacingSmall) {
                    ForEach(group.transactions) { transaction in
                        LedgerTransactionRow(transaction: transaction)
                    }
                }
            }
        }
    }
}

struct LedgerTransactionRow: View {
    let transaction: Transaction

    private var typeColor: Color {
        transaction.type == .income ? AppTheme.successColor : AppTheme.errorColor
    }

    var body: some View {
        HStack(spacing: AppTheme.spacingMedium) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: transaction.category.icon)
                        .foregroundStyle(transaction.category.color)
                    Text(transaction.category.name)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Text(transaction.note ?? "未命名记录")
                    .font(.body.weight(.medium))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(transaction.type == .income ? "+" : "-")¥\(String(format: "%.2f", transaction.amount))")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(typeColor)
                Text(transaction.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textTertiary)
            }
        }
        .padding(AppTheme.spacingMedium)
        .background(AppTheme.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium))
    }
}

struct LedgerGroup {
    let yearMonth: String
    let transactions: [Transaction]
}

#Preview {
    LedgerView(transactions: Transaction.generateMockData(using: Category.defaultCategories))
        .padding()
}
