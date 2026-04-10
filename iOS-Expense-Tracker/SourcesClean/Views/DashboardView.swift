import SwiftData
import SwiftUI

struct DashboardView: View {
    @Binding var showingAddTransaction: Bool
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]

    private var currentMonthTransactions: [Transaction] {
        let calendar = Calendar.current
        let now = Date()
        return transactions.filter { transaction in
            calendar.isDate(transaction.date, equalTo: now, toGranularity: .month)
        }
    }

    private var incomeThisMonth: Double {
        currentMonthTransactions
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }
    }

    private var expenseThisMonth: Double {
        currentMonthTransactions
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
    }

    private var netThisMonth: Double {
        incomeThisMonth - expenseThisMonth
    }

    private var recentTransactions: [Transaction] {
        Array(transactions.prefix(5))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.largeSpacing) {
                    summarySection
                    quickActionSection
                    recentSection
                }
                .padding(AppTheme.largeSpacing)
            }
            .navigationTitle("Overview")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddTransaction = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
        }
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.mediumSpacing) {
            Text("This month")
                .font(.headline)

            HStack(spacing: AppTheme.mediumSpacing) {
                MetricCard(title: "Income", amount: incomeThisMonth, color: AppTheme.successColor)
                MetricCard(title: "Expense", amount: expenseThisMonth, color: AppTheme.errorColor)
            }

            MetricCard(title: "Net", amount: netThisMonth, color: netThisMonth >= 0 ? AppTheme.primaryColor : AppTheme.warningColor)
        }
    }

    private var quickActionSection: some View {
        Button {
            showingAddTransaction = true
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Add transaction")
                    .fontWeight(.semibold)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .foregroundStyle(AppTheme.mutedText)
            }
            .padding(AppTheme.largeSpacing)
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.largeRadius))
        }
        .buttonStyle(.plain)
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.mediumSpacing) {
            HStack {
                Text("Recent")
                    .font(.headline)
                Spacer()
                NavigationLink("See all") {
                    TransactionListView()
                }
                .font(.subheadline)
            }

            if recentTransactions.isEmpty {
                EmptyStateCard(
                    title: "No transactions yet",
                    subtitle: "Add your first entry to start tracking."
                )
            } else {
                VStack(spacing: AppTheme.smallSpacing) {
                    ForEach(recentTransactions, id: \.id) { transaction in
                        TransactionListRow(transaction: transaction)
                    }
                }
            }
        }
    }
}

struct AddTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.sortOrder) private var categories: [Category]

    @State private var amount = ""
    @State private var note = ""
    @State private var type: TransactionType = .expense
    @State private var selectedCategoryID: UUID?
    @State private var showingValidationError = false
    @State private var validationMessage = ""

    private var availableCategories: [Category] {
        let matches = categories.filter { $0.type == type }
        return matches.isEmpty ? categories : matches
    }

    private var isAmountValid: Bool {
        guard let value = Double(amount) else {
            return false
        }
        return value > 0
    }

    var body: some View {
        Form {
            Section {
                TextField("Amount", text: $amount)
                    .keyboardType(.decimalPad)
                TextField("Note", text: $note)
            } header: {
                Text("Details")
            }

            Section {
                Picker("Type", selection: $type) {
                    ForEach(TransactionType.allCases) { transactionType in
                        Text(transactionType.rawValue).tag(transactionType)
                    }
                }
                .pickerStyle(.segmented)
            } header: {
                Text("Type")
            }

            Section {
                if availableCategories.isEmpty {
                    Text("Create a category in Settings before adding a transaction.")
                        .foregroundStyle(AppTheme.mutedText)
                } else {
                    Picker("Category", selection: $selectedCategoryID) {
                        ForEach(availableCategories, id: \.id) { category in
                            Text(category.name).tag(Optional(category.id))
                        }
                    }
                }
            } header: {
                Text("Category")
            }
        }
        .navigationTitle("New Transaction")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    saveTransaction()
                }
                .disabled(!isAmountValid || availableCategories.isEmpty)
            }
        }
        .alert("Invalid entry", isPresented: $showingValidationError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(validationMessage)
        }
        .onAppear {
            syncSelectedCategory()
        }
        .onChange(of: type) { _, _ in
            syncSelectedCategory()
        }
    }

    private func syncSelectedCategory() {
        if availableCategories.contains(where: { $0.id == selectedCategoryID }) {
            return
        }

        selectedCategoryID = availableCategories.first?.id
    }

    private func saveTransaction() {
        guard let amountValue = Double(amount), amountValue > 0 else {
            validationMessage = "Enter a valid amount greater than zero."
            showingValidationError = true
            return
        }

        guard let category = availableCategories.first(where: { $0.id == selectedCategoryID }) ?? availableCategories.first else {
            validationMessage = "Create a category before saving a transaction."
            showingValidationError = true
            return
        }

        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let transaction = Transaction(
            amount: amountValue,
            date: Date(),
            note: trimmedNote.isEmpty ? nil : trimmedNote,
            type: type,
            category: category
        )

        modelContext.insert(transaction)
        try? modelContext.save()
        dismiss()
    }
}

struct TransactionListRow: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: AppTheme.mediumSpacing) {
            Circle()
                .fill(transaction.category.color)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: transaction.category.icon)
                        .foregroundStyle(.white)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.note?.isEmpty == false ? transaction.note! : transaction.category.name)
                    .font(.body.weight(.semibold))
                Text(transaction.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(AppTheme.mutedText)
            }

            Spacer()

            Text(transaction.amount, format: .currency(code: "CNY"))
                .font(.body.weight(.semibold))
                .foregroundStyle(transaction.type.color)
        }
        .padding(AppTheme.mediumSpacing)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.mediumRadius))
    }
}

private struct MetricCard: View {
    let title: String
    let amount: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.smallSpacing) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(AppTheme.mutedText)
            Text(amount, format: .currency(code: "CNY"))
                .font(.title3.weight(.bold))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.largeSpacing)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.largeRadius))
    }
}

struct EmptyStateCard: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: AppTheme.smallSpacing) {
            Image(systemName: "tray")
                .font(.system(size: 28))
                .foregroundStyle(AppTheme.mutedText)
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(AppTheme.mutedText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.extraLargeSpacing)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.largeRadius))
    }
}
