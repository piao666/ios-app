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
    @Query private var categories: [Category]

    var body: some View {
        NavigationView {
            Form {
                Section("基本信息") {
                    TextField("金额", text: $amount)
                        .keyboardType(.decimalPad)
                    TextField("标题", text: $title)
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
                trailing: Button("保存") { saveTransaction() }
                    .disabled(amount.isEmpty || title.isEmpty)
            )
        }
    }

    private func saveTransaction() {
        guard let amountValue = Double(amount), !title.isEmpty else { return }

        let transaction = Transaction(
            amount: amountValue,
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