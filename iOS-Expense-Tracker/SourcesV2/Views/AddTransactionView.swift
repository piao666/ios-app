import SwiftData
import SwiftUI

struct AddTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var themeSettings: ThemeSettings
    @Query(sort: \Category.sortOrder) private var categories: [Category]

    @State private var amount = ""
    @State private var note = ""
    @State private var date = Date()
    @State private var type: TransactionType = .expense
    @State private var selectedCategoryID: UUID?
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""

    private var themeColors: ThemeColorSet {
        ThemeManager.getColorSet(isDark: themeSettings.isDarkMode)
    }

    private var availableCategories: [Category] {
        let matching = categories.filter { $0.type == type }
        return matching.isEmpty ? categories : matching
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppTheme.spacingLarge) {
                HStack(spacing: AppTheme.spacingSmall) {
                    ForEach(TransactionType.allCases) { currentType in
                        Button {
                            type = currentType
                            selectedCategoryID = availableCategories.first?.id
                        } label: {
                            Text(currentType.rawValue)
                                .font(.system(size: AppTheme.fontSizeBody, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(type == currentType ? currentType.color : themeColors.chipBackground)
                                .foregroundStyle(type == currentType ? Color.white : themeColors.textSecondary)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
                        }
                        .buttonStyle(.plain)
                    }
                }

                addField(title: "金额") {
                    TextField("输入金额", text: $amount)
                        .keyboardType(.decimalPad)
                }

                addField(title: "分类") {
                    Picker("分类", selection: $selectedCategoryID) {
                        ForEach(availableCategories, id: \.id) { category in
                            Text(category.name).tag(Optional(category.id))
                        }
                    }
                    .pickerStyle(.menu)
                }

                addField(title: "时间") {
                    DatePicker("时间", selection: $date, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                }

                addField(title: "备注") {
                    TextField("输入备注", text: $note, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }

                Button("保存") {
                    saveTransaction()
                }
                .font(.system(size: AppTheme.fontSizeBody, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(themeColors.primaryColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
            }
            .padding(AppTheme.spacingLarge)
        }
        .background(themeColors.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("新增交易")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("关闭") {
                    dismiss()
                }
            }
        }
        .onAppear {
            selectedCategoryID = availableCategories.first?.id
        }
        .onChange(of: type) { _, _ in
            selectedCategoryID = availableCategories.first?.id
        }
        .alert("保存失败", isPresented: $showingErrorAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    @ViewBuilder
    private func addField<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: AppTheme.fontSizeCaption, weight: .medium))
                .foregroundStyle(themeColors.textSecondary)

            content()
                .padding(.horizontal, AppTheme.spacingMedium)
                .padding(.vertical, 12)
                .background(themeColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)
                        .stroke(themeColors.cardBorder, lineWidth: 1)
                )
        }
    }

    private func saveTransaction() {
        guard let amountValue = Double(amount), amountValue > 0 else {
            errorMessage = "请输入大于 0 的金额。"
            showingErrorAlert = true
            return
        }

        guard let category = availableCategories.first(where: { $0.id == selectedCategoryID }) ?? availableCategories.first else {
            errorMessage = "没有可用分类，请先到设置页创建分类。"
            showingErrorAlert = true
            return
        }

        let transaction = Transaction(
            amount: amountValue,
            date: date,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            type: type,
            category: category
        )

        modelContext.insert(transaction)
        try? modelContext.save()
        dismiss()
    }
}
