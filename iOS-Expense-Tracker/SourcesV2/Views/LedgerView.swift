import SwiftData
import SwiftUI

private enum LedgerScope: String, CaseIterable, Identifiable {
    case month = "月账本"
    case year = "年账本"

    var id: String { rawValue }
}

private struct LedgerGroup: Identifiable {
    let id: String
    let title: String
    let transactions: [Transaction]
    let income: Double
    let expense: Double
}

struct LedgerView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var themeSettings: ThemeSettings

    let transactions: [Transaction]

    @State private var scope: LedgerScope = .month

    private var themeColors: ThemeColorSet {
        ThemeManager.getColorSet(isDark: themeSettings.isDarkMode)
    }

    private var groupedLedgers: [LedgerGroup] {
        let groups: [String: [Transaction]]

        switch scope {
        case .month:
            groups = Dictionary(grouping: transactions) { Transaction.formatYearMonth($0.date) }
        case .year:
            groups = Dictionary(grouping: transactions) {
                String(Calendar.current.component(.year, from: $0.date))
            }
        }

        return groups.map { key, items in
            LedgerGroup(
                id: key,
                title: displayTitle(for: key),
                transactions: items.sorted { $0.date > $1.date },
                income: items.filter { $0.type == .income }.reduce(0) { $0 + $1.amount },
                expense: items.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
            )
        }
        .sorted { $0.id > $1.id }
    }

    var body: some View {
        Group {
            if groupedLedgers.isEmpty {
                emptyState
            } else {
                List {
                    Section {
                        Picker("账本维度", selection: $scope) {
                            ForEach(LedgerScope.allCases) { item in
                                Text(item.rawValue).tag(item)
                            }
                        }
                        .pickerStyle(.segmented)
                        .listRowBackground(themeColors.backgroundPrimary)
                    }

                    ForEach(groupedLedgers) { group in
                        Section {
                            ForEach(group.transactions, id: \.id) { transaction in
                                NavigationLink {
                                    TransactionDetailView(transaction: transaction)
                                } label: {
                                    HStack(spacing: AppTheme.spacingMedium) {
                                        Image(systemName: transaction.category.icon)
                                            .foregroundStyle(transaction.category.color)
                                            .frame(width: 22)

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(transaction.displayTitle)
                                                .font(.system(size: AppTheme.fontSizeBody, weight: .semibold))
                                                .foregroundStyle(themeColors.textPrimary)
                                            Text(transaction.date.formatted(date: .numeric, time: .shortened))
                                                .font(.system(size: AppTheme.fontSizeCaption))
                                                .foregroundStyle(themeColors.textSecondary)
                                        }

                                        Spacer()

                                        Text(transaction.signedAmountText)
                                            .font(.system(size: AppTheme.fontSizeBody, weight: .bold))
                                            .foregroundStyle(transaction.type.color)
                                    }
                                    .padding(.vertical, 4)
                                }
                                .swipeActions {
                                    Button(role: .destructive) {
                                        modelContext.delete(transaction)
                                        try? modelContext.save()
                                    } label: {
                                        Label("删除", systemImage: "trash")
                                    }
                                }
                                .listRowBackground(themeColors.cardBackground)
                            }
                        } header: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(group.title)
                                    .font(.system(size: 17, weight: .bold))
                                Text("收入 \(group.income.formatted(.currency(code: "CNY"))) · 支出 \(group.expense.formatted(.currency(code: "CNY")))")
                                    .font(.system(size: AppTheme.fontSizeCaption))
                                    .foregroundStyle(themeColors.textSecondary)
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .background(themeColors.backgroundPrimary)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: AppTheme.spacingMedium) {
            Picker("账本维度", selection: $scope) {
                ForEach(LedgerScope.allCases) { item in
                    Text(item.rawValue).tag(item)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, AppTheme.spacingLarge)

            VStack(spacing: AppTheme.spacingSmall) {
                Image(systemName: "book.closed")
                    .font(.system(size: 36))
                    .foregroundStyle(themeColors.textTertiary)
                Text("还没有账本数据")
                    .font(.system(size: AppTheme.fontSizeBody, weight: .medium))
                    .foregroundStyle(themeColors.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(themeColors.backgroundPrimary)
    }

    private func displayTitle(for key: String) -> String {
        switch scope {
        case .year:
            return "\(key)年"
        case .month:
            let inputFormatter = DateFormatter()
            inputFormatter.locale = Locale(identifier: "zh_CN")
            inputFormatter.dateFormat = "yyyy-MM"

            guard let date = inputFormatter.date(from: key) else {
                return key
            }

            let outputFormatter = DateFormatter()
            outputFormatter.locale = Locale(identifier: "zh_CN")
            outputFormatter.dateFormat = "yyyy年M月"
            return outputFormatter.string(from: date)
        }
    }
}
