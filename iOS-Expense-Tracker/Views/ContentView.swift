import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var transactions: [Transaction]
    @Query private var categories: [Category]

    @State private var showingAddTransaction = false
    @State private var selectedTab = 0
    @State private var showingLedger = false

    var body: some View {
        TabView(selection: $selectedTab) {
            // MARK: - Tab 0：仪表盘（NavigationStack 由 DashboardView 自己管理）
            DashboardView(showingAddTransaction: $showingAddTransaction)
                .tabItem { Label("仪表盘", systemImage: "square.grid.2x2") }
                .tag(0)

            // MARK: - Tab 1：交易列表
            TransactionListView()
                .tabItem { Label("交易", systemImage: "list.bullet") }
                .tag(1)

            // MARK: - Tab 2：统计
            NavigationStack {
                if showingLedger {
                    LedgerView(transactions: transactions)
                        .navigationTitle("账单簿")
                } else {
                    ScrollView {
                        ExpensePieChartView(transactions: transactions)
                            .padding()
                    }
                    .navigationTitle("统计")
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: { withAnimation { showingLedger.toggle() } }) {
                        Text(showingLedger ? "统计" : "账单簿")
                            .font(.system(size: AppTheme.fontSizeSmall, weight: .semibold))
                            .foregroundColor(AppTheme.primaryColor)
                    }
                }
            }
            .tabItem { Label("统计", systemImage: "chart.pie") }
            .tag(2)

            // MARK: - Tab 3：设置
            NavigationStack {
                SettingsView()
            }
            .tabItem { Label("设置", systemImage: "gear") }
            .tag(3)
        }
        .tint(AppTheme.primaryColor)
        .sheet(isPresented: $showingAddTransaction) {
            AddTransactionView()
        }
        .onAppear {
            // 1. 插入默认分类（只在首次安装 / 数据库为空时执行一次）
            if categories.isEmpty {
                for category in Category.defaultCategories {
                    modelContext.insert(category)
                }
                // 确保分类写入后再查询，此处用 try? save 刷新上下文
                try? modelContext.save()
            }
            // 2. 注入 Mock 测试数据（只在交易为空且分类已就绪时执行）
            //    使用已存在的分类对象，根治设置页分类重复问题
            if transactions.isEmpty && !categories.isEmpty {
                let mockData = Transaction.generateMockData(using: Array(categories))
                for transaction in mockData {
                    modelContext.insert(transaction)
                }
            }
        }
    }
}

// MARK: - 交易行（供旧版列表复用）
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

// MARK: - 添加交易
struct AddTransactionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var amount = ""
    @State private var note = ""
    @State private var type: TransactionType = .expense
    @State private var selectedCategory: Category?
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @Query private var categories: [Category]

    var isAmountValid: Bool {
        guard !amount.isEmpty, let v = Double(amount) else { return false }
        return v > 0
    }

    var body: some View {
        NavigationView {
            Form {
                Section("基本信息") {
                    TextField("金额", text: $amount).keyboardType(.decimalPad)
                    TextField("备注", text: $note)
                }
                Section("类型") {
                    Picker("类型", selection: $type) {
                        ForEach(TransactionType.allCases, id: \.self) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Section("分类") {
                    Picker("分类", selection: $selectedCategory) {
                        Text("无").tag(nil as Category?)
                        ForEach(categories) { cat in
                            HStack {
                                Image(systemName: cat.icon).foregroundColor(cat.color)
                                Text(cat.name)
                            }
                            .tag(cat as Category?)
                        }
                    }
                }
            }
            .navigationTitle("添加记录")
            .navigationBarItems(
                leading: Button("取消") { dismiss() },
                trailing: Button("保存") { validateAndSave() }.disabled(!isAmountValid)
            )
            .alert("输入错误", isPresented: $showingErrorAlert) {
                Button("确定") {}
            } message: { Text(errorMessage) }
        }
    }

    private func validateAndSave() {
        guard let amountValue = Double(amount) else { return }
        guard let category = selectedCategory ?? categories.first else {
            errorMessage = "分类信息不完整，无法保存"
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
        dismiss()
    }
}