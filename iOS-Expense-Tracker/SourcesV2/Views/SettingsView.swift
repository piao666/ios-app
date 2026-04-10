import SwiftData
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var themeSettings: ThemeSettings
    @Query(sort: \Category.sortOrder) private var categories: [Category]

    @State private var showingAddCategory = false

    private var themeColors: ThemeColorSet {
        ThemeManager.getColorSet(isDark: themeSettings.isDarkMode)
    }

    var body: some View {
        List {
            Section("外观") {
                Toggle(isOn: Binding(
                    get: { themeSettings.isDarkMode },
                    set: { themeSettings.isDarkMode = $0 }
                )) {
                    Label("深色模式", systemImage: themeSettings.isDarkMode ? "moon.fill" : "sun.max.fill")
                }
                .tint(themeColors.primaryColor)
            }

            Section("快捷功能") {
                Label("语音记账已保留", systemImage: "waveform")
                    .foregroundStyle(themeColors.textPrimary)
                Text("首页顶部可以切换“语音记账 / 手动记账”，右上角保留深色模式切换和新增按钮。")
                    .font(.system(size: AppTheme.fontSizeCaption))
                    .foregroundStyle(themeColors.textSecondary)
            }

            Section("分类管理") {
                ForEach(categories, id: \.id) { category in
                    HStack(spacing: AppTheme.spacingMedium) {
                        Circle()
                            .fill(category.color.opacity(0.14))
                            .frame(width: 42, height: 42)
                            .overlay {
                                Image(systemName: category.icon)
                                    .foregroundStyle(category.color)
                            }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(category.name)
                                .font(.system(size: AppTheme.fontSizeBody, weight: .semibold))
                            Text(category.type.rawValue)
                                .font(.system(size: AppTheme.fontSizeCaption))
                                .foregroundStyle(themeColors.textSecondary)
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(themeColors.backgroundPrimary)
        .navigationTitle("设置")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddCategory = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddCategory) {
            NavigationStack {
                CategoryEditorView()
            }
        }
    }
}

private struct CategoryEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var themeSettings: ThemeSettings
    @Query(sort: \Category.sortOrder) private var categories: [Category]

    @State private var name = ""
    @State private var icon = "tag.fill"
    @State private var colorHex = "4F46E5"
    @State private var type: TransactionType = .expense

    private var themeColors: ThemeColorSet {
        ThemeManager.getColorSet(isDark: themeSettings.isDarkMode)
    }

    var body: some View {
        Form {
            Section("基础信息") {
                TextField("分类名称", text: $name)
                Picker("收支类型", selection: $type) {
                    ForEach(TransactionType.allCases) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                TextField("图标", text: $icon)
                TextField("颜色 Hex", text: $colorHex)
            }
        }
        .navigationTitle("新增分类")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("取消") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("保存") {
                    saveCategory()
                }
                .foregroundStyle(themeColors.primaryColor)
            }
        }
    }

    private func saveCategory() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedIcon = icon.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedHex = colorHex.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            return
        }

        let category = Category(
            name: trimmedName,
            icon: trimmedIcon.isEmpty ? "tag.fill" : trimmedIcon,
            colorHex: trimmedHex.isEmpty ? "4F46E5" : trimmedHex,
            type: type,
            sortOrder: categories.count
        )

        modelContext.insert(category)
        try? modelContext.save()
        dismiss()
    }
}
