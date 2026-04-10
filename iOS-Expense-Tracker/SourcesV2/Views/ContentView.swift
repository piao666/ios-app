import SwiftData
import SwiftUI

private enum AppTab: Int, Hashable {
    case home
    case transactions
    case statistics
    case settings
}

private enum StatisticsMode {
    case chart
    case ledger
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var themeSettings: ThemeSettings
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @Query(sort: \Category.sortOrder) private var categories: [Category]

    @State private var selectedTab: AppTab = .home
    @State private var showingAddTransaction = false
    @State private var statisticsMode: StatisticsMode = .chart

    private var themeColors: ThemeColorSet {
        ThemeManager.getColorSet(isDark: themeSettings.isDarkMode)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                DashboardView(showingAddTransaction: $showingAddTransaction)
            }
            .tabItem { Label("首页", systemImage: "house.fill") }
            .tag(AppTab.home)

            NavigationStack {
                TransactionListView()
            }
            .tabItem { Label("交易", systemImage: "list.bullet") }
            .tag(AppTab.transactions)

            NavigationStack {
                StatisticsContainerView(
                    transactions: transactions,
                    mode: $statisticsMode
                )
            }
            .tabItem { Label("统计", systemImage: "chart.pie.fill") }
            .tag(AppTab.statistics)

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label("设置", systemImage: "gearshape.fill") }
            .tag(AppTab.settings)
        }
        .tint(themeColors.primaryColor)
        .sheet(isPresented: $showingAddTransaction) {
            NavigationStack {
                AddTransactionView()
            }
            .presentationDetents([.large])
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

        let workingCategories: [Category]

        if needsCategories {
            workingCategories = Category.defaultCategories
            workingCategories.forEach { modelContext.insert($0) }
        } else {
            workingCategories = categories
        }

        if needsTransactions {
            Transaction.generateMockData(using: workingCategories).forEach { modelContext.insert($0) }
        }

        try? modelContext.save()
    }
}

private struct StatisticsContainerView: View {
    @EnvironmentObject private var themeSettings: ThemeSettings

    let transactions: [Transaction]
    @Binding var mode: StatisticsMode
    @State private var showingAddTransaction = false

    private var themeColors: ThemeColorSet {
        ThemeManager.getColorSet(isDark: themeSettings.isDarkMode)
    }

    var body: some View {
        Group {
            switch mode {
            case .chart:
                ScrollView(showsIndicators: false) {
                    ExpensePieChartView(transactions: transactions)
                        .padding(.horizontal, AppTheme.spacingLarge)
                        .padding(.vertical, AppTheme.spacingLarge)
                }
            case .ledger:
                LedgerView(transactions: transactions)
            }
        }
        .background(themeColors.backgroundPrimary.ignoresSafeArea())
        .navigationTitle(mode == .chart ? "统计分析" : "账本")
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if mode == .ledger {
                    Button {
                        showingAddTransaction = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }

                Button(mode == .chart ? "账本" : "图表") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        mode = mode == .chart ? .ledger : .chart
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddTransaction) {
            NavigationStack {
                AddTransactionView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ThemeSettings())
        .modelContainer(Transaction.previewContainer)
}
