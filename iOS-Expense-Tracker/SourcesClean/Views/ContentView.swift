import SwiftData
import SwiftUI

private enum AppTab: Int, Hashable {
    case dashboard
    case transactions
    case statistics
    case settings
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @Query(sort: \Category.sortOrder) private var categories: [Category]

    @State private var selectedTab: AppTab = .dashboard
    @State private var showingAddTransaction = false
    @State private var showingLedger = false

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(showingAddTransaction: $showingAddTransaction)
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(AppTab.dashboard)

            NavigationStack {
                TransactionListView()
            }
            .tabItem { Label("Transactions", systemImage: "list.bullet") }
            .tag(AppTab.transactions)

            NavigationStack {
                Group {
                    if showingLedger {
                        LedgerView(transactions: transactions)
                    } else {
                        ScrollView {
                            ExpensePieChartView(transactions: transactions)
                                .padding(AppTheme.largeSpacing)
                        }
                    }
                }
                .navigationTitle(showingLedger ? "Ledger" : "Statistics")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(showingLedger ? "Chart" : "Ledger") {
                            showingLedger.toggle()
                        }
                    }
                }
            }
            .tabItem { Label("Stats", systemImage: "chart.pie.fill") }
            .tag(AppTab.statistics)

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label("Settings", systemImage: "gearshape.fill") }
            .tag(AppTab.settings)
        }
        .tint(AppTheme.primaryColor)
        .sheet(isPresented: $showingAddTransaction) {
            NavigationStack {
                AddTransactionView()
            }
        }
        .task {
            seedInitialDataIfNeeded()
        }
    }

    private func seedInitialDataIfNeeded() {
        let needsCategories = categories.isEmpty
        let needsTransactions = transactions.isEmpty

        guard needsCategories || needsTransactions else {
            return
        }

        var workingCategories = categories

        if needsCategories {
            workingCategories = Category.defaultCategories
            workingCategories.forEach { modelContext.insert($0) }
        }

        if needsTransactions {
            Transaction.generateMockData(using: workingCategories).forEach { modelContext.insert($0) }
        }

        try? modelContext.save()
    }
}
