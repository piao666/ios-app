import SwiftData
import SwiftUI

struct SettingsView: View {
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @Environment(\.modelContext) private var modelContext
    @State private var showingAddCategory = false

    var body: some View {
        List {
            Section("分类管理") {
                ForEach(categories) { category in
                    NavigationLink {
                        EditCategoryView(category: category)
                    } label: {
                        HStack {
                            Image(systemName: category.icon)
                                .foregroundStyle(category.color)
                            Text(category.name)
                            Spacer()
                            Text(category.type.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete(perform: deleteCategory)
                .onMove(perform: moveCategory)
            } footer: {
                Button("添加新分类") {
                    showingAddCategory = true
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 8)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("设置")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
        }
        .sheet(isPresented: $showingAddCategory) {
            NavigationStack {
                AddCategoryView()
            }
        }
    }

    private func deleteCategory(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(categories[index])
        }
        try? modelContext.save()
    }

    private func moveCategory(from source: IndexSet, to destination: Int) {
        var reordered = Array(categories)
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, category) in reordered.enumerated() {
            category.sortOrder = index
        }
        try? modelContext.save()
    }
}

struct AddCategoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.sortOrder) private var categories: [Category]

    @State private var name = ""
    @State private var selectedIcon = "tag"
    @State private var selectedColorHex = "007AFF"
    @State private var type: TransactionType = .expense

    private let iconOptions: [(icon: String, label: String)] = [
        ("fork.knife", "餐饮"),
        ("car", "交通"),
        ("bag", "购物"),
        ("gamecontroller", "娱乐"),
        ("house", "住房"),
        ("heart", "医疗"),
        ("book", "教育"),
        ("banknote", "工资"),
        ("chart.line.uptrend.xyaxis", "理财"),
        ("gift", "礼物"),
        ("airplane", "出行"),
        ("desktopcomputer", "数码")
    ]

    private let colorOptions = [
        "FF9500", "5856D6", "FF2D55", "AF52DE",
        "34C759", "FF3B30", "5AC8FA", "4CD964",
        "007AFF", "FFD93D", "FF6B6B", "4ECDC4"
    ]

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Form {
            Section("分类名称") {
                TextField("例如：宠物、健身、旅行", text: $name)
            }

            Section("类型") {
                Picker("类型", selection: $type) {
                    Text("支出").tag(TransactionType.expense)
                    Text("收入").tag(TransactionType.income)
                }
                .pickerStyle(.segmented)
            }

            Section("图标") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                    ForEach(iconOptions, id: \.icon) { option in
                        Button {
                            selectedIcon = option.icon
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: option.icon)
                                    .font(.system(size: 22))
                                    .foregroundStyle(selectedIcon == option.icon ? (Color(hex: selectedColorHex) ?? .blue) : Color.gray)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        (selectedIcon == option.icon ? (Color(hex: selectedColorHex) ?? .blue) : Color(.systemGray6)).opacity(0.16)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                Text(option.label)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 8)
            }

            Section("颜色") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                    ForEach(colorOptions, id: \.self) { hex in
                        Button {
                            selectedColorHex = hex
                        } label: {
                            Circle()
                                .fill(Color(hex: hex) ?? .blue)
                                .frame(width: 34, height: 34)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 2)
                                        .opacity(selectedColorHex == hex ? 1 : 0)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 8)
            }

            Section("预览") {
                HStack {
                    Image(systemName: selectedIcon)
                        .foregroundStyle(Color(hex: selectedColorHex) ?? .blue)
                    Text(name.isEmpty ? "分类名称" : name)
                    Spacer()
                    Text(type.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("新增分类")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("取消") { dismiss() }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button("保存") {
                    let category = Category(
                        name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                        icon: selectedIcon,
                        colorHex: selectedColorHex,
                        type: type,
                        sortOrder: categories.count
                    )
                    modelContext.insert(category)
                    try? modelContext.save()
                    dismiss()
                }
                .disabled(!isValid)
            }
        }
    }
}

struct EditCategoryView: View {
    @Bindable var category: Category
    @Environment(\.modelContext) private var modelContext

    private let iconOptions: [(icon: String, label: String)] = [
        ("fork.knife", "餐饮"),
        ("car", "交通"),
        ("bag", "购物"),
        ("gamecontroller", "娱乐"),
        ("house", "住房"),
        ("heart", "医疗"),
        ("book", "教育"),
        ("banknote", "工资"),
        ("chart.line.uptrend.xyaxis", "理财"),
        ("gift", "礼物"),
        ("airplane", "出行"),
        ("desktopcomputer", "数码")
    ]

    private let colorOptions = [
        "FF9500", "5856D6", "FF2D55", "AF52DE",
        "34C759", "FF3B30", "5AC8FA", "4CD964",
        "007AFF", "FFD93D", "FF6B6B", "4ECDC4"
    ]

    var body: some View {
        Form {
            Section("分类名称") {
                TextField("分类名称", text: $category.name)
            }

            Section("类型") {
                Picker("类型", selection: $category.type) {
                    Text("支出").tag(TransactionType.expense)
                    Text("收入").tag(TransactionType.income)
                }
                .pickerStyle(.segmented)
            }

            Section("图标") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                    ForEach(iconOptions, id: \.icon) { option in
                        Button {
                            category.icon = option.icon
                            try? modelContext.save()
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: option.icon)
                                    .font(.system(size: 22))
                                    .foregroundStyle(category.icon == option.icon ? category.color : Color.gray)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        (category.icon == option.icon ? category.color : Color(.systemGray6)).opacity(0.16)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                Text(option.label)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 8)
            }

            Section("颜色") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                    ForEach(colorOptions, id: \.self) { hex in
                        Button {
                            category.colorHex = hex
                            try? modelContext.save()
                        } label: {
                            Circle()
                                .fill(Color(hex: hex) ?? .blue)
                                .frame(width: 34, height: 34)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 2)
                                        .opacity(category.colorHex == hex ? 1 : 0)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("编辑分类")
        .onDisappear {
            try? modelContext.save()
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .modelContainer(Transaction.previewContainer)
}
