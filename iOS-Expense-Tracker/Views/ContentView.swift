import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var transactions: [Transaction]
    @Query private var categories: [Category]

    @State private var showingAddTransaction = false
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                DashboardView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: { showingAddTransaction = true }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(AppTheme.primaryColor)
                            }
                        }
                    }
                    .sheet(isPresented: $showingAddTransaction) {
                        AddTransactionView()
                    }
            }
            .tabItem {
                Label("仪表盘", systemImage: "square.grid.2x2")
            }
            .tag(0)

            TransactionListView()
                .tabItem {
                    Label("交易", systemImage: "list.bullet")
                }
                .tag(1)

            NavigationView {
                ExpensePieChartView(transactions: transactions)
                    .navigationTitle("统计")
            }
            .tabItem {
                Label("统计", systemImage: "chart.pie")
            }
            .tag(2)

            NavigationView {
                SettingsView()
            }
            .tabItem {
                Label("设置", systemImage: "gear")
            }
            .tag(3)
        }
        .tint(AppTheme.primaryColor)
        .onAppear {
            // 1. 初始化默认分类
            if categories.isEmpty {
                for category in Category.defaultCategories {
                    modelContext.insert(category)
                }
            }
            
            // 2. 🚨 海总 UAT 真机测试专用后门：如果发现数据库是空的，强制注入 12 条高保真时间轴数据
            if transactions.isEmpty {
                print("正在向真机环境注入 S3 高保真测试数据...")
                let mockData = Transaction.generateMockData()
                for transaction in mockData {
                    modelContext.insert(transaction)
                }
            }
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
                // 修复：模型中已移除 title，统一使用 note
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
        guard !amount.isEmpty else { return false }
        guard let amountValue = Double(amount) else { return false }
        return amountValue > 0
    }

    var body: some View {
        NavigationView {
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
                        Text("无").tag(nil as Category?)
                        ForEach(categories) { category in
                            HStack {
                                Image(systemName: category.icon)
                                    .foregroundColor(category.color)
                                Text(category.name)
                            }
                            .tag(category as Category?)
                        }
                    }
                }
            }
            .navigationTitle("添加记录")
            .navigationBarItems(
                leading: Button("取消") { dismiss() },
                trailing: Button("保存") { validateAndSave() }
                    .disabled(!isAmountValid)
            )
            .alert("输入错误", isPresented: $showingErrorAlert) {
                Button("确定") { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func validateAndSave() {
        guard let amountValue = Double(amount) else { return }

        guard let category = selectedCategory ?? categories.first else {
            errorMessage = "分类信息不完整，无法保存"
            showingErrorAlert = true
            return
        }

        // 修复：适配增强型初始化构造器
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