import Charts
import SwiftUI

private struct CategorySlice: Identifiable {
    let id: UUID
    let name: String
    let icon: String
    let color: Color
    let amount: Double
}

struct ExpensePieChartView: View {
    let transactions: [Transaction]

    private var slices: [CategorySlice] {
        let grouped = Dictionary(grouping: transactions.filter { $0.type == .expense }) { $0.category.id }

        return grouped.compactMap { _, items in
            guard let category = items.first?.category else {
                return nil
            }

            return CategorySlice(
                id: category.id,
                name: category.name,
                icon: category.icon,
                color: category.color,
                amount: items.reduce(0) { $0 + $1.amount }
            )
        }
        .sorted { $0.amount > $1.amount }
    }

    private var totalExpense: Double {
        slices.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.largeSpacing) {
            Text("Spending by category")
                .font(.headline)

            if slices.isEmpty {
                EmptyStateCard(
                    title: "No expense data",
                    subtitle: "Add expense transactions to see the chart."
                )
            } else {
                Chart(slices) { slice in
                    SectorMark(
                        angle: .value("Amount", slice.amount),
                        innerRadius: .ratio(0.58),
                        angularInset: 2
                    )
                    .foregroundStyle(slice.color)
                    .annotation(position: .overlay) {
                        if totalExpense > 0, slice.amount / totalExpense >= 0.12 {
                            Text("\(Int((slice.amount / totalExpense) * 100))%")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .frame(height: 240)

                VStack(spacing: AppTheme.smallSpacing) {
                    ForEach(slices) { slice in
                        HStack(spacing: AppTheme.mediumSpacing) {
                            Circle()
                                .fill(slice.color)
                                .frame(width: 12, height: 12)
                            Image(systemName: slice.icon)
                                .foregroundStyle(slice.color)
                            Text(slice.name)
                            Spacer()
                            Text(slice.amount, format: .currency(code: "CNY"))
                                .fontWeight(.semibold)
                        }
                        .padding(AppTheme.mediumSpacing)
                        .background(AppTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.mediumRadius))
                    }
                }
            }
        }
    }
}
