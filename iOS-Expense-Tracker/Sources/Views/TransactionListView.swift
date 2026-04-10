import SwiftData
import SwiftUI

struct TransactionListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]

    @State private var searchText = ""
    @State private var selectedFilter: TransactionFilter = .all
    @State private var selectedTransaction: Transaction?

    private var groupedTransactions: [(date: Date, transactions: [Transaction])] {
        let calendar = Calendar.current
        let filtered = filterTransactions(transactions)
        let grouped = Dictionary(grouping: filtered) { transaction in
            calendar.startOfDay(for: transaction.date)
        }

        return grouped
            .sorted { $0.key > $1.key }
            .map { (date: $0.key, transactions: $0.value) }
    }

    var body: some View {
        VStack(spacing: 0) {
            SearchFilterBar(searchText: $searchText, selectedFilter: $selectedFilter)
            TimelineListView(groupedTransactions: groupedTransactions) { transaction in
                selectedTransaction = transaction
            }
        }
        .navigationTitle("交易记录")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $selectedTransaction) { transaction in
            TransactionDetailView(transaction: transaction)
        }
    }

    private func filterTransactions(_ list: [Transaction]) -> [Transaction] {
        var result = list

        if !searchText.isEmpty {
            let keyword = searchText.lowercased()
            result = result.filter { transaction in
                transaction.searchKeywords?.contains(keyword) ?? false
                    || transaction.category.name.contains(searchText)
                    || (transaction.note?.contains(searchText) ?? false)
            }
        }

        switch selectedFilter {
        case .expense:
            result = result.filter { $0.type == .expense }
        case .income:
            result = result.filter { $0.type == .income }
        case .today:
            result = result.filter { Calendar.current.isDateInToday($0.date) }
        case .week:
            let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? .distantPast
            result = result.filter { $0.date >= weekAgo }
        case .month:
            let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? .distantPast
            result = result.filter { $0.date >= monthAgo }
        case .all:
            break
        }

        return result
    }
}

struct SearchFilterBar: View {
    @Binding var searchText: String
    @Binding var selectedFilter: TransactionFilter

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("搜索交易...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
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

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(TransactionFilter.allCases) { filter in
                        FilterChip(
                            title: filter.title,
                            isSelected: selectedFilter == filter
                        ) {
                            selectedFilter = filter
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct TimelineListView: View {
    let groupedTransactions: [(date: Date, transactions: [Transaction])]
    let onTransactionTap: (Transaction) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                ForEach(Array(groupedTransactions.enumerated()), id: \.element.date) { _, group in
                    Section {
                        ForEach(group.transactions) { transaction in
                            TimelineTransactionRow(transaction: transaction) {
                                onTransactionTap(transaction)
                            }
                            .padding(.bottom, 4)
                        }
                    } header: {
                        TimelineDateHeader(
                            date: group.date,
                            count: group.transactions.count,
                            totalAmount: group.transactions.reduce(0) { $0 + $1.amount }
                        )
                    }
                }
            }
            .padding(.bottom, 20)
        }
    }
}

struct TimelineDateHeader: View {
    let date: Date
    let count: Int
    let totalAmount: Double

    private var displayText: String {
        if Calendar.current.isDateInToday(date) {
            return "今天"
        }

        if Calendar.current.isDateInYesterday(date) {
            return "昨天"
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")

        if Calendar.current.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            formatter.dateFormat = "EEEE"
        } else {
            formatter.dateFormat = "M月d日"
        }

        return formatter.string(from: date)
    }

    private var fullDateText: String {
        guard !Calendar.current.isDateInToday(date), !Calendar.current.isDateInYesterday(date) else {
            return ""
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日"
        return formatter.string(from: date)
    }

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .center, spacing: 2) {
                Text(displayText)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(Calendar.current.isDateInToday(date) ? .blue : .primary)
                if !fullDateText.isEmpty {
                    Text(fullDateText)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 70)

            ZStack {
                Rectangle()
                    .fill(Color(.systemGray4))
                    .frame(width: 2)
                Circle()
                    .fill(Calendar.current.isDateInToday(date) ? Color.blue : Color(.systemGray3))
                    .frame(width: 12, height: 12)
            }

            Text("\(count) 笔")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color(.systemGray5))
                .clipShape(Capsule())

            Spacer()

            Text(totalAmount, format: .currency(code: "CNY"))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
}

struct TimelineTransactionRow: View {
    let transaction: Transaction
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(width: 2)
                    Circle()
                        .fill(transaction.type == .expense ? Color.red : Color.green)
                        .frame(width: 8, height: 8)
                }
                .frame(width: 70)

                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(transaction.category.color.opacity(0.15))
                            .frame(width: 44, height: 44)
                        Image(systemName: transaction.category.icon)
                            .font(.title3)
                            .foregroundStyle(transaction.category.color)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(transaction.category.name)
                            .font(.body.weight(.semibold))
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

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(transaction.amount, format: .currency(code: "CNY"))
                            .font(.body.weight(.bold))
                            .foregroundStyle(transaction.type == .expense ? .red : .green)
                        if transaction.hasAttachments {
                            Image(systemName: "paperclip")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 12)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
            }
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
    }
}

struct TransactionDetailView: View {
    let transaction: Transaction

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showDeleteConfirm = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text(transaction.amount, format: .currency(code: "CNY"))
                            .font(.system(size: 48, weight: .bold))
                            .foregroundStyle(transaction.type == .expense ? .red : .green)
                        Label(transaction.type.rawValue, systemImage: transaction.type.icon)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 20)

                    ZStack {
                        Circle()
                            .fill(transaction.category.color.opacity(0.15))
                            .frame(width: 80, height: 80)
                        Image(systemName: transaction.category.icon)
                            .font(.system(size: 36))
                            .foregroundStyle(transaction.category.color)
                    }

                    VStack(spacing: 0) {
                        DetailRow(icon: "tag.fill", title: "分类", value: transaction.category.name, color: transaction.category.color)
                        Divider().padding(.leading, 56)
                        DetailRow(icon: "calendar", title: "日期", value: transaction.date.formatted(date: .long, time: .omitted))
                        Divider().padding(.leading, 56)
                        DetailRow(icon: "clock", title: "时间", value: transaction.date.formatted(date: .omitted, time: .shortened))
                        if let note = transaction.note, !note.isEmpty {
                            Divider().padding(.leading, 56)
                            DetailRow(icon: "text.alignleft", title: "备注", value: note)
                        }
                        if transaction.hasAttachments {
                            Divider().padding(.leading, 56)
                            DetailRow(icon: "paperclip", title: "附件", value: "\(transaction.allAttachments.count) 个")
                        }
                    }
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("删除记录", systemImage: "trash")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.12))
                            .foregroundStyle(.red)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("交易详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
            .confirmationDialog("确认删除这条记录？", isPresented: $showDeleteConfirm) {
                Button("删除", role: .destructive) {
                    modelContext.delete(transaction)
                    try? modelContext.save()
                    dismiss()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("删除后无法恢复。")
            }
        }
    }
}

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    var color: Color = .blue

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 32)
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }
}

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

#Preview {
    NavigationStack {
        TransactionListView()
    }
    .modelContainer(Transaction.previewContainer)
}
