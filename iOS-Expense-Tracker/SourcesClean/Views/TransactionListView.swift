import SwiftData
import SwiftUI

enum TransactionFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case expense = "Expense"
    case income = "Income"
    case thisMonth = "This Month"

    var id: String { rawValue }
}

struct TransactionListView: View {
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]

    @State private var searchText = ""
    @State private var selectedFilter: TransactionFilter = .all
    @State private var selectedTransaction: Transaction?

    private var filteredTransactions: [Transaction] {
        transactions.filter { transaction in
            matchesFilter(transaction) && matchesSearch(transaction)
        }
    }

    var body: some View {
        VStack(spacing: AppTheme.mediumSpacing) {
            Picker("Filter", selection: $selectedFilter) {
                ForEach(TransactionFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, AppTheme.largeSpacing)

            if filteredTransactions.isEmpty {
                EmptyStateCard(
                    title: "No matching transactions",
                    subtitle: "Adjust the filter or add a new transaction."
                )
                .padding(.horizontal, AppTheme.largeSpacing)
            } else {
                List {
                    ForEach(filteredTransactions, id: \.id) { transaction in
                        Button {
                            selectedTransaction = transaction
                        } label: {
                            TransactionListRow(transaction: transaction)
                                .padding(.vertical, 2)
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Transactions")
        .searchable(text: $searchText, prompt: "Search notes or categories")
        .sheet(item: $selectedTransaction) { transaction in
            NavigationStack {
                TransactionDetailView(transaction: transaction)
            }
        }
    }

    private func matchesSearch(_ transaction: Transaction) -> Bool {
        guard !searchText.isEmpty else {
            return true
        }

        let query = searchText.lowercased()
        return transaction.searchKeywords.contains(query)
    }

    private func matchesFilter(_ transaction: Transaction) -> Bool {
        switch selectedFilter {
        case .all:
            return true
        case .expense:
            return transaction.type == .expense
        case .income:
            return transaction.type == .income
        case .thisMonth:
            return Calendar.current.isDate(transaction.date, equalTo: Date(), toGranularity: .month)
        }
    }
}

struct TransactionDetailView: View {
    let transaction: Transaction

    var body: some View {
        Form {
            Section {
                LabeledContent("Amount") {
                    Text(transaction.amount, format: .currency(code: "CNY"))
                        .foregroundStyle(transaction.type.color)
                }
                LabeledContent("Type", value: transaction.type.rawValue)
                LabeledContent("Category", value: transaction.category.name)
                LabeledContent("Date", value: transaction.date.formatted(date: .long, time: .shortened))
            } header: {
                Text("Overview")
            }

            if let note = transaction.note, !note.isEmpty {
                Section {
                    Text(note)
                } header: {
                    Text("Note")
                }
            }
        }
        .navigationTitle("Transaction")
    }
}
