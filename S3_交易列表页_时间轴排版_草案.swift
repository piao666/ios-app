//
//  TransactionListView.swift
//  iOS记账应用 - S3阶段交易列表页重构
//  时间轴高级排版结构草案
//

import SwiftUI
import SwiftData

// MARK: - 主视图：交易列表页
struct TransactionListView: View {
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @State private var searchText: String = ""
    @State private var selectedFilter: TransactionFilter = .all
    @State private var selectedTransaction: Transaction?
    @State private var showDetailSheet = false
    
    // 按日期分组的数据
    private var groupedTransactions: [(date: Date, transactions: [Transaction])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: transactions) { transaction in
            calendar.startOfDay(for: transaction.date)
        }
        return grouped.sorted { $0.key > $1.key }.map { (date: $0.key, transactions: $0.value) }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 搜索和筛选栏
                SearchFilterBar(searchText: $searchText, selectedFilter: $selectedFilter)
                
                // 时间轴列表
                TimelineListView(
                    groupedTransactions: groupedTransactions,
                    onTransactionTap: { transaction in
                        selectedTransaction = transaction
                        showDetailSheet = true
                    }
                )
            }
            .navigationTitle("交易记录")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { /* 添加交易 */ }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showDetailSheet) {
                if let transaction = selectedTransaction {
                    TransactionDetailView(transaction: transaction)
                }
            }
        }
    }
}

// MARK: - 搜索和筛选栏
struct SearchFilterBar: View {
    @Binding var searchText: String
    @Binding var selectedFilter: TransactionFilter
    @State private var showFilterSheet = false
    
    var body: some View {
        VStack(spacing: 12) {
            // 搜索框
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                
                TextField("搜索交易...", text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
            
            // 筛选按钮
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(TransactionFilter.allCases) { filter in
                        FilterChip(
                            title: filter.title,
                            isSelected: selectedFilter == filter,
                            action: { selectedFilter = filter }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }
}

// MARK: - 筛选芯片
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

// MARK: - 时间轴列表视图
struct TimelineListView: View {
    let groupedTransactions: [(date: Date, transactions: [Transaction])]
    let onTransactionTap: (Transaction) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                ForEach(groupedTransactions, id: \.date) { group in
                    Section {
                        // 该日期的所有交易
                        ForEach(group.transactions) { transaction in
                            TimelineTransactionRow(
                                transaction: transaction,
                                onTap: { onTransactionTap(transaction) }
                            )
                        }
                    } header: {
                        // 日期头部（粘性）
                        TimelineDateHeader(date: group.date, count: group.transactions.count)
                    }
                }
            }
        }
    }
}

// MARK: - 时间轴日期头部
struct TimelineDateHeader: View {
    let date: Date
    let count: Int
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    private var isYesterday: Bool {
        Calendar.current.isDateInYesterday(date)
    }
    
    private var displayText: String {
        if isToday { return "今天" }
        if isYesterday { return "昨天" }
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        
        // 本周内显示星期几
        if Calendar.current.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        }
        
        // 其他显示完整日期
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // 日期标签
            VStack(alignment: .center, spacing: 2) {
                Text(displayText)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                if !isToday && !isYesterday {
                    Text(date, style: .date)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 60, alignment: .center)
            
            // 时间轴线
            ZStack {
                Rectangle()
                    .fill(Color(.systemGray4))
                    .frame(width: 2)
                
                Circle()
                    .fill(isToday ? Color.blue : Color(.systemGray3))
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(isToday ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 4)
                    )
            }
            
            // 交易数量
            Text("\(count)笔")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.systemGray6))
                .clipShape(Capsule())
            
            Spacer()
            
            // 当日总金额
            Text("¥1,234.56")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
}

// MARK: - 时间轴交易行
struct TimelineTransactionRow: View {
    let transaction: Transaction
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // 时间轴线
                ZStack {
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(width: 2)
                    
                    Circle()
                        .fill(transaction.type == .expense ? Color.red : Color.green)
                        .frame(width: 8, height: 8)
                }
                .frame(width: 60)
                
                // 交易内容
                HStack(spacing: 12) {
                    // 分类图标
                    ZStack {
                        Circle()
                            .fill(transaction.category.color.opacity(0.15))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: transaction.category.icon)
                            .font(.title3)
                            .foregroundStyle(transaction.category.color)
                    }
                    
                    // 交易信息
                    VStack(alignment: .leading, spacing: 4) {
                        Text(transaction.category.name)
                            .font(.body)
                            .fontWeight(.medium)
                        
                        if let note = transaction.note, !note.isEmpty {
                            Text(note)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        
                        Text(transaction.date, style: .time)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    // 金额
                    Text(transaction.amount, format: .currency(code: "CNY"))
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(transaction.type == .expense ? .red : .green)
                }
                .padding(.vertical, 8)
                .padding(.trailing)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 交易详情视图
struct TransactionDetailView: View {
    let transaction: Transaction
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 金额大标题
                    VStack(spacing: 8) {
                        Text(transaction.amount, format: .currency(code: "CNY"))
                            .font(.system(size: 48, weight: .bold))
                            .foregroundStyle(transaction.type == .expense ? .red : .green)
                        
                        Text(transaction.type == .expense ? "支出" : "收入")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // 详细信息卡片
                    VStack(spacing: 0) {
                        DetailRow(icon: "tag.fill", title: "分类", value: transaction.category.name)
                        Divider()
                        DetailRow(icon: "calendar", title: "日期", value: transaction.date.formatted())
                        Divider()
                        DetailRow(icon: "clock", title: "时间", value: transaction.date.formatted(date: .omitted, time: .shortened))
                        if let note = transaction.note, !note.isEmpty {
                            Divider()
                            DetailRow(icon: "text.alignleft", title: "备注", value: note)
                        }
                    }
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    
                    // 操作按钮
                    HStack(spacing: 16) {
                        Button(action: { /* 编辑 */ }) {
                            Label("编辑", systemImage: "pencil")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        Button(action: { /* 删除 */ }) {
                            Label("删除", systemImage: "trash")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .foregroundStyle(.red)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("交易详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 详情行组件
struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 32)
            
            Text(title)
                .font(.body)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .fontWeight(.medium)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }
}

// MARK: - 筛选枚举
enum TransactionFilter: String, CaseIterable, Identifiable {
    case all = "全部"
    case expense = "支出"
    case income = "收入"
    case today = "今天"
    case week = "本周"
    case month = "本月"
    
    var id: String { rawValue }
    
    var title: String { rawValue }
}

// MARK: - 预览
#Preview {
    TransactionListView()
}