import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @Query(sort: \Category.sortOrder) private var categories: [Category]

    @State private var showingAddTransaction = false
    @State private var selectedTab = 0
    @State private var showingLedger = false

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(showingAddTransaction: $showingAddTransaction)
                .tabItem { Label("首页", systemImage: "square.grid.2x2") }
                .tag(0)

            NavigationStack {
                TransactionListView()
            }
            .tabItem { Label("交易", systemImage: "list.bullet") }
            .tag(1)

            NavigationStack {
                Group {
                    if showingLedger {
                        LedgerView(transactions: transactions)
                    } else {
                        ScrollView {
                            ExpensePieChartView(transactions: transactions)
                                .padding()
                        }
                    }
                }
                .navigationTitle(showingLedger ? "账本" : "统计")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(showingLedger ? "图表" : "账本") {
                            withAnimation {
                                showingLedger.toggle()
                            }
                        }
                    }
                }
            }
            .tabItem { Label("统计", systemImage: "chart.pie") }
            .tag(2)

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label("设置", systemImage: "gear") }
            .tag(3)
        }
        .tint(AppTheme.primaryColor)
        .sheet(isPresented: $showingAddTransaction) {
            NavigationStack {
                AddTransactionView()
            }
        }
        .onAppear(perform: seedInitialDataIfNeeded)
    }

    private func seedInitialDataIfNeeded() {
        if categories.isEmpty {
            let defaultCategories = Category.defaultCategories
            defaultCategories.forEach { modelContext.insert($0) }
            Transaction.generateMockData(using: defaultCategories).forEach { modelContext.insert($0) }
            try? modelContext.save()
            return
        }

        if transactions.isEmpty {
            Transaction.generateMockData(using: Array(categories)).forEach { modelContext.insert($0) }
            try? modelContext.save()
        }
    }
}

struct TransactionRow: View {
    let transaction: Transaction

    var typeColor: Color {
        transaction.type == .income ? AppTheme.successColor : AppTheme.errorColor
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppTheme.spacingSmall) {
                Text(transaction.note ?? "未命名记录")
                    .font(.system(size: AppTheme.fontSizeLarge, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                Text(transaction.date, style: .date)
                    .font(.system(size: AppTheme.fontSizeSmall))
                    .foregroundColor(AppTheme.textTertiary)
            }

            Spacer()

            HStack(spacing: 2) {
                Text(transaction.type == .income ? "+" : "-")
                    .font(.system(size: AppTheme.fontSizeLarge, weight: .semibold))
                    .foregroundColor(typeColor)
                Text("¥\(transaction.amount, specifier: "%.2f")")
                    .font(.system(size: AppTheme.fontSizeLarge, weight: .semibold))
                    .foregroundColor(typeColor)
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
    @State private var selectedCategory: Category?
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""

    var isAmountValid: Bool {
        guard let value = Double(amount) else {
            return false
        }
        return value > 0
    }

    var body: some View {
        Form {
            Section("基本信息") {
                TextField("金额", text: $amount)
                    .keyboardType(.decimalPad)
                TextField("备注", text: $note)
            }

            Section("类型") {
                Picker("类型", selection: $type) {
                    ForEach(TransactionType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("分类") {
                Picker("分类", selection: $selectedCategory) {
                    Text("请选择").tag(nil as Category?)
                    ForEach(categories) { category in
                        Label(category.name, systemImage: category.icon)
                            .tag(category as Category?)
                    }
                }
            }
        }
        .navigationTitle("新增记录")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("取消") { dismiss() }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button("保存", action: validateAndSave)
                    .disabled(!isAmountValid)
            }
        }
        .alert("输入错误", isPresented: $showingErrorAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            if selectedCategory == nil {
                selectedCategory = categories.first
            }
        }
    }

    private func validateAndSave() {
        guard let amountValue = Double(amount), amountValue > 0 else {
            errorMessage = "请输入有效的金额。"
            showingErrorAlert = true
            return
        }

        guard let category = selectedCategory ?? categories.first else {
            errorMessage = "请先创建至少一个分类。"
            showingErrorAlert = true
            return
        }

        let transaction = Transaction(
            amount: amountValue,
            date: Date(),
            note: note.isEmpty ? nil : note,
            type: type,
            category: category
        )

        modelContext.insert(transaction)
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    ContentView()
        .modelContainer(Transaction.previewContainer)
}
