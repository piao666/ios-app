import SwiftUI

private struct LedgerMonth: Identifiable {
    let id: String
    let title: String
    let income: Double
    let expense: Double
    let transactions: [Transaction]

    var incomeText: String {
        income.formatted(.currency(code: "CNY"))
    }

    var expenseText: String {
        expense.formatted(.currency(code: "CNY"))
    }
}

struct LedgerView: View {
    let transactions: [Transaction]

    private var months: [LedgerMonth] {
        let grouped = Dictionary(grouping: transactions) { Transaction.monthKey(for: $0.date) }

        return grouped
            .map { key, items in
                LedgerMonth(
                    id: key,
                    title: displayTitle(for: key),
                    income: items.filter { $0.type == .income }.reduce(0) { $0 + $1.amount },
                    expense: items.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount },
                    transactions: items.sorted { $0.date > $1.date }
                )
            }
            .sorted { $0.id > $1.id }
    }

    var body: some View {
        if months.isEmpty {
            EmptyStateCard(
                title: "No ledger data",
                subtitle: "Transactions will appear here once you start tracking."
            )
            .padding(AppTheme.largeSpacing)
        } else {
            List {
                ForEach(months) { month in
                    Section {
                        ForEach(month.transactions, id: \.id) { transaction in
                            TransactionListRow(transaction: transaction)
                                .listRowInsets(EdgeInsets())
                                .padding(.vertical, 4)
                        }
                    } header: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(month.title)
                                .font(.headline)
                            Text("Income: \(month.incomeText)  Expense: \(month.expenseText)")
                                .font(.caption)
                                .foregroundStyle(AppTheme.mutedText)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }

    private func displayTitle(for key: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"

        guard let date = formatter.date(from: key) else {
            return key
        }

        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: date)
    }
}
