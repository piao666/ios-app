import SwiftData
import SwiftUI

struct TransactionDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var themeSettings: ThemeSettings

    let transaction: Transaction

    @State private var showingEditor = false
    @State private var showingDeleteAlert = false

    private var themeColors: ThemeColorSet {
        ThemeManager.getColorSet(isDark: themeSettings.isDarkMode)
    }

    private var amountColor: Color {
        transaction.type == .expense ? themeColors.errorColor : themeColors.successColor
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppTheme.spacingXLarge) {
                amountSection
                detailSection
                actionSection
            }
            .padding(AppTheme.spacingLarge)
        }
        .background(themeColors.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("交易详情")
        .sheet(isPresented: $showingEditor) {
            NavigationStack {
                AddTransactionView(editingTransaction: transaction)
            }
        }
        .alert("确认删除这笔交易？", isPresented: $showingDeleteAlert) {
            Button("删除", role: .destructive) {
                modelContext.delete(transaction)
                try? modelContext.save()
                dismiss()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("删除后将无法恢复。")
        }
    }

    private var amountSection: some View {
        VStack(spacing: AppTheme.spacingSmall) {
            Text(transaction.amount, format: .currency(code: "CNY"))
                .font(.system(size: 56, weight: .bold))
                .foregroundStyle(amountColor)
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            Label(transaction.type.rawValue, systemImage: transaction.type.icon)
                .font(.system(size: AppTheme.fontSizeBody, weight: .semibold))
                .foregroundStyle(themeColors.textSecondary)

            Circle()
                .fill(transaction.category.color.opacity(0.15))
                .frame(width: 96, height: 96)
                .overlay {
                    Image(systemName: transaction.category.icon)
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(transaction.category.color)
                }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, AppTheme.spacingMedium)
    }

    private var detailSection: some View {
        VStack(spacing: 0) {
            detailRow(title: "分类", value: transaction.category.name, icon: "tag.fill")
            detailRow(title: "日期", value: transaction.date.formatted(date: .long, time: .omitted), icon: "calendar")
            detailRow(title: "时间", value: transaction.date.formatted(date: .omitted, time: .shortened), icon: "clock")
            detailRow(title: "备注", value: transaction.note.isEmpty ? "无" : transaction.note, icon: "text.alignleft")
        }
        .background(themeColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge)
                .stroke(themeColors.cardBorder, lineWidth: 1)
        )
    }

    private var actionSection: some View {
        HStack(spacing: AppTheme.spacingMedium) {
            Button {
                showingEditor = true
            } label: {
                Label("编辑", systemImage: "pencil")
                    .font(.system(size: AppTheme.fontSizeBody, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(themeColors.primaryColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium))
            }
            .buttonStyle(.plain)

            Button {
                showingDeleteAlert = true
            } label: {
                Label("删除", systemImage: "trash")
                    .font(.system(size: AppTheme.fontSizeBody, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(themeColors.errorColor.opacity(0.15))
                    .foregroundStyle(themeColors.errorColor)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium))
            }
            .buttonStyle(.plain)
        }
    }

    private func detailRow(title: String, value: String, icon: String) -> some View {
        HStack(spacing: AppTheme.spacingMedium) {
            Image(systemName: icon)
                .foregroundStyle(themeColors.primaryColor)
                .frame(width: 22)

            Text(title)
                .font(.system(size: AppTheme.fontSizeBody))
                .foregroundStyle(themeColors.textSecondary)

            Spacer()

            Text(value)
                .font(.system(size: AppTheme.fontSizeBody, weight: .semibold))
                .foregroundStyle(themeColors.textPrimary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, AppTheme.spacingLarge)
        .padding(.vertical, 14)
        .overlay(alignment: .bottom) {
            Divider()
                .padding(.leading, 52)
                .opacity(title == "备注" ? 0 : 1)
        }
    }
}
