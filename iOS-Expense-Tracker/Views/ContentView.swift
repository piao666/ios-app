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
            // 第一个Tab - 仪表盘（数据概览页）
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

            // 第二个Tab - 交易列表
            NavigationView {
                List {
                    ForEach(transactions) { transaction in
                        TransactionRow(transaction: transaction)
                    }
                    .onDelete(perform: deleteTransactions)
                }
                .navigationTitle("交易列表")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                    ToolbarItem {
                        Button(action: { showingAddTransaction = true }) {
                            Label("添加", systemImage: "plus")
                        }
                    }
                }
                .sheet(isPresented: $showingAddTransaction) {
                    AddTransactionView()
                }
            }
            .tabItem {
                Label("交易", systemImage: "list.bullet")
            }
            .tag(1)

            // 第三个Tab - 统计页面
            NavigationView {
                VStack {
                    Text("统计功能待实现")
                        .font(.title)
                        .foregroundColor(AppTheme.textSecondary)
                }
                .navigationTitle("统计")
            }
            .tabItem {
                Label("统计", systemImage: "chart.pie")
            }
            .tag(2)

            // 第四个Tab - 设置页面
            NavigationView {
                Form {
                    Section("数据管理") {
                        Button(action: { exportDataBackup() }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundColor(AppTheme.primaryColor)
                                Text("导出数据备份")
                                    .foregroundColor(AppTheme.textPrimary)
                                Spacer()
                            }
                        }

                        Button(action: { importDataBackup() }) {
                            HStack {
                                Image(systemName: "square.and.arrow.down")
                                    .foregroundColor(AppTheme.primaryColor)
                                Text("导入数据备份")
                                    .foregroundColor(AppTheme.textPrimary)
                                Spacer()
                            }
                        }
                    }

                    Section("分类管理") {
                        ForEach(categories) { category in
                            HStack {
                                Image(systemName: category.icon)
                                    .foregroundColor(Color(hex: category.color))
                                Text(category.name)
                            }
                        }
                    }

                    Section("关于") {
                        HStack {
                            Text("版本")
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                }
                .navigationTitle("设置")
            }
            .tabItem {
                Label("设置", systemImage: "gear")
            }
            .tag(3)
        }
        .tint(AppTheme.primaryColor)
        .onAppear {
            // 初始化默认分类
            if categories.isEmpty {
                for category in Category.defaultCategories {
                    modelContext.insert(category)
                }
            }
        }
    }

    private func deleteTransactions(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(transactions[index])
            }
        }
    }

    private func exportDataBackup() {
        // TODO: 实现数据导出功能
        print("📤 已触发数据导出功能，将支持 JSON/CSV 格式导出")
    }

    private func importDataBackup() {
        // TODO: 实现数据导入功能
        print("📥 已触发数据导入功能，将支持从备份文件还原数据")
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
                Text(transaction.title)
                    .font(.system(size: AppTheme.fontSizeLarge, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)

                if let note = transaction.note {
                    Text(note)
                        .font(.system(size: AppTheme.fontSizeSmall))
                        .foregroundColor(AppTheme.textSecondary)
                }

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
    @State private var title = ""
    @State private var note = ""
    @State private var type: TransactionType = .expense
    @State private var selectedCategory: Category?
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @Query private var categories: [Category]

    // 验证金额输入是否有效
    var isAmountValid: Bool {
        guard !amount.isEmpty else { return false }
        guard let amountValue = Double(amount) else { return false }
        return amountValue > 0
    }

    var isSaveButtonDisabled: Bool {
        title.isEmpty || !isAmountValid
    }

    var body: some View {
        NavigationView {
            Form {
                Section("基本信息") {
                    TextField("金额（必填）", text: $amount)
                        .keyboardType(.decimalPad)
                        .onChange(of: amount) { oldValue, newValue in
                            // 只允许数字和小数点
                            let filtered = newValue.filter { $0.isNumber || $0 == "." }
                            // 确保只有一个小数点
                            let components = filtered.split(separator: ".", omittingEmptySubsequences: false)
                            if components.count > 2 {
                                amount = oldValue
                            } else {
                                amount = filtered
                            }
                        }

                    TextField("标题（必填）", text: $title)
                    TextField("备注（可选）", text: $note)
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
                                    .foregroundColor(Color(hex: category.color))
                                Text(category.name)
                            }
                            .tag(category as Category?)
                        }
                    }
                }
            }
            .navigationTitle("添加交易")
            .navigationBarItems(
                leading: Button("取消") { dismiss() },
                trailing: Button("保存") { validateAndSave() }
                    .disabled(isSaveButtonDisabled)
            )
            .alert("输入验证失败", isPresented: $showingErrorAlert) {
                Button("确定") { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func validateAndSave() {
        // 验证标题
        if title.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "请输入交易标题"
            showingErrorAlert = true
            return
        }

        // 验证金额
        guard let amountValue = Double(amount) else {
            errorMessage = "金额必须是有效的数字"
            showingErrorAlert = true
            return
        }

        if amountValue <= 0 {
            errorMessage = "金额必须大于 0"
            showingErrorAlert = true
            return
        }

        saveTransaction(amount: amountValue)
    }

    private func saveTransaction(amount: Double) {
        let transaction = Transaction(
            amount: amount,
            title: title,
            note: note.isEmpty ? nil : note,
            type: type,
            category: selectedCategory
        )

        modelContext.insert(transaction)
        dismiss()
    }
}

// 颜色扩展
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Transaction.self, Category.self], inMemory: true)
}