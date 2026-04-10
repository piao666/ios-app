import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var themeSettings: ThemeSettings
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]

    @State private var editMode: EditMode = .inactive
    @State private var showingAddCategory = false
    @State private var showingDeleteBlockedAlert = false
    @State private var deleteBlockedMessage = ""

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

            Section("分类管理") {
                ForEach(categories, id: \.id) { category in
                    NavigationLink {
                        CategoryEditorView(category: category)
                    } label: {
                        HStack(spacing: AppTheme.spacingMedium) {
                            Circle()
                                .fill(category.color.opacity(0.14))
                                .frame(width: 38, height: 38)
                                .overlay {
                                    Image(systemName: category.icon)
                                        .foregroundStyle(category.color)
                                }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(category.name)
                                    .font(.system(size: AppTheme.fontSizeBody, weight: .semibold))
                                Text(category.type.rawValue)
                                    .font(.system(size: AppTheme.fontSizeCaption))
                                    .foregroundStyle(themeColors.textSecondary)
                            }
                        }
                    }
                }
                .onDelete(perform: deleteCategories)
                .onMove(perform: moveCategories)
            }

            Section {
                Button {
                    showingAddCategory = true
                } label: {
                    Text("添加新分类")
                        .font(.system(size: AppTheme.fontSizeBody, weight: .semibold))
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .environment(\.editMode, $editMode)
        .scrollContentBackground(.hidden)
        .background(themeColors.backgroundPrimary)
        .navigationTitle("设置")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(editMode == .active ? "完成" : "Edit") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        editMode = editMode == .active ? .inactive : .active
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddCategory) {
            NavigationStack {
                CategoryEditorView(category: nil)
            }
        }
        .alert("无法删除分类", isPresented: $showingDeleteBlockedAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(deleteBlockedMessage)
        }
    }

    private func deleteCategories(at offsets: IndexSet) {
        var blocked: [String] = []
        var deletedCategoryIDs: Set<UUID> = []

        for index in offsets {
            let category = categories[index]
            let isInUse = transactions.contains { $0.category.id == category.id }

            if isInUse {
                blocked.append(category.name)
                continue
            }

            deletedCategoryIDs.insert(category.id)
            modelContext.delete(category)
        }

        if !blocked.isEmpty {
            deleteBlockedMessage = "以下分类正在被交易使用：\(blocked.joined(separator: "、"))。请先修改或删除相关交易。"
            showingDeleteBlockedAlert = true
        }

        let remainingCategories = categories.filter { !deletedCategoryIDs.contains($0.id) }
        for (index, category) in remainingCategories.enumerated() {
            category.sortOrder = index
        }
        try? modelContext.save()
    }

    private func moveCategories(from source: IndexSet, to destination: Int) {
        var reordered = categories
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, category) in reordered.enumerated() {
            category.sortOrder = index
        }
        try? modelContext.save()
    }

}

private struct CategoryEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var themeSettings: ThemeSettings
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]

    let category: Category?

    @State private var name = ""
    @State private var selectedIcon = "tag.fill"
    @State private var selectedColorHex = "4F46E5"
    @State private var type: TransactionType = .expense
    @State private var didPrefill = false
    @State private var showingDeleteBlockedAlert = false
    @State private var showingDeleteConfirm = false

    private var themeColors: ThemeColorSet {
        ThemeManager.getColorSet(isDark: themeSettings.isDarkMode)
    }

    private var isEditing: Bool {
        category != nil
    }

    private static let iconOptions: [String] = [
        "fork.knife", "car.fill", "bag.fill", "house.fill", "gamecontroller.fill",
        "cross.case.fill", "book.fill", "banknote.fill", "chart.line.uptrend.xyaxis",
        "gift.fill", "cart.fill", "airplane", "tram.fill", "heart.fill", "stethoscope",
        "figure.run", "pawprint.fill", "music.note", "film.fill", "laptopcomputer"
    ]

    private static let colorOptions: [(name: String, hex: String, color: Color)] = [
        ("蓝", "2563EB", Color(hex: "2563EB") ?? .blue),
        ("绿", "16A34A", Color(hex: "16A34A") ?? .green),
        ("红", "DC2626", Color(hex: "DC2626") ?? .red),
        ("橙", "F97316", Color(hex: "F97316") ?? .orange),
        ("粉", "DB2777", Color(hex: "DB2777") ?? .pink),
        ("紫", "7C3AED", Color(hex: "7C3AED") ?? .purple),
        ("青", "0EA5E9", Color(hex: "0EA5E9") ?? .cyan),
        ("黄", "CA8A04", Color(hex: "CA8A04") ?? .yellow)
    ]

    var body: some View {
        Form {
            Section("基础信息") {
                TextField("分类名称", text: $name)
                Picker("收支类型", selection: $type) {
                    ForEach(TransactionType.allCases) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
            }

            Section("选择图标") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 10) {
                    ForEach(Self.iconOptions, id: \.self) { icon in
                        Button {
                            selectedIcon = icon
                        } label: {
                            Image(systemName: icon)
                                .font(.system(size: 18, weight: .semibold))
                                .frame(maxWidth: .infinity, minHeight: 36)
                                .background(selectedIcon == icon ? themeColors.primaryColor.opacity(0.2) : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Section("选择颜色") {
                HStack(spacing: 10) {
                    ForEach(Self.colorOptions, id: \.hex) { option in
                        Button {
                            selectedColorHex = option.hex
                        } label: {
                            Circle()
                                .fill(option.color)
                                .frame(width: 28, height: 28)
                                .overlay {
                                    if selectedColorHex == option.hex {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundStyle(.white)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Section("预览") {
                HStack(spacing: AppTheme.spacingMedium) {
                    Circle()
                        .fill((Color(hex: selectedColorHex) ?? themeColors.primaryColor).opacity(0.14))
                        .frame(width: 40, height: 40)
                        .overlay {
                            Image(systemName: selectedIcon)
                                .foregroundStyle(Color(hex: selectedColorHex) ?? themeColors.primaryColor)
                        }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(name.isEmpty ? "未命名分类" : name)
                        Text(type.rawValue)
                            .font(.system(size: AppTheme.fontSizeCaption))
                            .foregroundStyle(themeColors.textSecondary)
                    }
                }
            }

            if isEditing {
                Section {
                    Button(role: .destructive) {
                        showingDeleteConfirm = true
                    } label: {
                        Text("删除此分类")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
        }
        .navigationTitle(isEditing ? "编辑分类" : "新增分类")
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
        .task {
            prefillIfNeeded()
        }
        .alert("无法删除分类", isPresented: $showingDeleteBlockedAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text("该分类已被交易使用，请先修改或删除相关交易。")
        }
        .alert("确认删除该分类？", isPresented: $showingDeleteConfirm) {
            Button("删除", role: .destructive) {
                deleteCategory()
            }
            Button("取消", role: .cancel) {}
        }
    }

    private func prefillIfNeeded() {
        guard !didPrefill else { return }
        didPrefill = true

        guard let category else { return }
        name = category.name
        selectedIcon = category.icon
        selectedColorHex = category.colorHex
        type = category.type
    }

    private func saveCategory() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            return
        }

        if let category {
            category.name = trimmedName
            category.icon = selectedIcon
            category.colorHex = selectedColorHex
            category.type = type

            // Keep searchable text in sync after category edits.
            for transaction in transactions where transaction.category.id == category.id {
                transaction.searchText = Transaction.makeSearchText(
                    note: transaction.note,
                    categoryName: category.name,
                    type: transaction.type.rawValue
                )
            }
        } else {
            let newCategory = Category(
                name: trimmedName,
                icon: selectedIcon,
                colorHex: selectedColorHex,
                type: type,
                sortOrder: categories.count
            )
            modelContext.insert(newCategory)
        }

        try? modelContext.save()
        dismiss()
    }

    private func deleteCategory() {
        guard let category else { return }

        let inUse = transactions.contains { $0.category.id == category.id }
        guard !inUse else {
            showingDeleteBlockedAlert = true
            return
        }

        modelContext.delete(category)
        try? modelContext.save()
        dismiss()
    }
}
