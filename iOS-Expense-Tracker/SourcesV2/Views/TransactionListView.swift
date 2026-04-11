import SwiftData
import SwiftUI

struct TransactionListView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var themeSettings: ThemeSettings
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]

    @State private var searchText = ""
    @State private var selectedFilter: TransactionFilter = .all

    private var themeColors: ThemeColorSet {
        ThemeManager.getColorSet(isDark: themeSettings.isDarkMode)
    }

    private var filteredTransactions: [Transaction] {
        transactions.filter { transaction in
            let passesFilter = selectedFilter.includes(transaction)
            let passesSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || transaction.searchText.contains(searchText.lowercased())
            return passesFilter && passesSearch
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppTheme.spacingLarge) {
                searchSection
                filterSection
                transactionSection
            }
            .padding(.horizontal, AppTheme.spacingLarge)
            .padding(.top, AppTheme.spacingMedium)
            .padding(.bottom, AppTheme.spacingXXLarge)
        }
        .background(themeColors.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("交易记录")
    }

    private var searchSection: some View {
        HStack(spacing: AppTheme.spacingSmall) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(themeColors.textTertiary)

            TextField("搜索备注或分类", text: $searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, AppTheme.spacingMedium)
        .padding(.vertical, 12)
        .background(themeColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)
                .stroke(themeColors.cardBorder, lineWidth: 1)
        )
    }

    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.spacingSmall) {
                ForEach(TransactionFilter.allCases) { filter in
                    Button {
                        selectedFilter = filter
                    } label: {
                        Text(filter.title)
                            .font(.system(size: AppTheme.fontSizeBody, weight: .semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(selectedFilter == filter ? themeColors.primaryColor : themeColors.chipBackground)
                            .foregroundStyle(selectedFilter == filter ? Color.white : themeColors.textSecondary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var transactionSection: some View {
        VStack(spacing: AppTheme.spacingSmall) {
            if filteredTransactions.isEmpty {
                VStack(spacing: AppTheme.spacingSmall) {
                    Image(systemName: "tray")
                        .font(.system(size: 28))
                        .foregroundStyle(themeColors.textTertiary)
                    Text("没有符合条件的记录")
                        .font(.system(size: AppTheme.fontSizeBody, weight: .medium))
                        .foregroundStyle(themeColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(AppTheme.spacingXXLarge)
                .background(themeColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge)
                        .stroke(themeColors.cardBorder, lineWidth: 1)
                )
            } else {
                ForEach(filteredTransactions, id: \.id) { transaction in
                    NavigationLink {
                        TransactionDetailView(transaction: transaction)
                    } label: {
                        TransactionRowCard(transaction: transaction, themeColors: themeColors)
                    }
                    .buttonStyle(.plain)
                    .swipeActions {
                        Button(role: .destructive) {
                            modelContext.delete(transaction)
                            try? modelContext.save()
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }
}

private struct TransactionRowCard: View {
    let transaction: Transaction
    let themeColors: ThemeColorSet

    var body: some View {
        HStack(spacing: AppTheme.spacingMedium) {
            Circle()
                .fill(transaction.category.color.opacity(0.14))
                .frame(width: 52, height: 52)
                .overlay {
                    Image(systemName: transaction.category.icon)
                        .foregroundStyle(transaction.category.color)
                        .font(.system(size: 18, weight: .bold))
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.displayTitle)
                    .font(.system(size: AppTheme.fontSizeSubtitle, weight: .bold))
                    .foregroundStyle(themeColors.textPrimary)
                    .lineLimit(1)
                Text(transaction.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: AppTheme.fontSizeCaption))
                    .foregroundStyle(themeColors.textSecondary)
            }

            Spacer()

            Text(transaction.signedAmountText)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(transaction.type.color)
        }
        .padding(AppTheme.spacingMedium)
        .background(themeColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)
                .stroke(themeColors.cardBorder, lineWidth: 1)
        )
    }
}
