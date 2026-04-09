import SwiftUI
import SwiftData

// MARK: - 设置主页
struct SettingsView: View {
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @Environment(\.modelContext) private var modelContext
    @State private var showingAddCategory = false   // 添加分类 Sheet 触发器

    var body: some View {
        List {
            Section {
                ForEach(categories) { category in
                    // 修复：NavigationLink 指向真实的 EditCategoryView
                    NavigationLink(destination: EditCategoryView(category: category)) {
                        HStack {
                            Image(systemName: category.icon)
                                .foregroundColor(category.color)
                            Text(category.name)
                        }
                    }
                }
                .onDelete(perform: deleteCategory)
                .onMove(perform: moveCategory)
            } footer: {
                // 修复：绑定 Sheet 触发器，点击弹出 AddCategoryView
                Button {
                    showingAddCategory = true
                } label: {
                    Text("添加新分类")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 10)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
        }
        // 修复：Sheet 真正绑定到 showingAddCategory
        .sheet(isPresented: $showingAddCategory) {
            AddCategoryView()
        }
    }

    private func deleteCategory(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(categories[index])
        }
    }

    private func moveCategory(from source: IndexSet, to destination: Int) {
        var revised = categories.map { $0 }
        revised.move(fromOffsets: source, toOffset: destination)
        for (index, cat) in revised.enumerated() {
            cat.sortOrder = index
        }
    }
}

// MARK: - 添加分类
struct AddCategoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Category.sortOrder) private var categories: [Category]

    @State private var name = ""
    @State private var selectedIcon = "tag"
    @State private var selectedColorHex = "007AFF"
    @State private var type: TransactionType = .expense

    // 常用图标候选
    private let iconOptions: [(icon: String, label: String)] = [
        ("fork.knife", "餐饮"), ("car", "交通"), ("bag", "购物"),
        ("gamecontroller", "娱乐"), ("house", "住房"), ("heart", "医疗"),
        ("book", "教育"), ("banknote", "工资"), ("chart.line.uptrend.xyaxis", "理财"),
        ("tag", "其他"), ("gift", "礼物"), ("airplane", "出行"),
        ("fitness.timer", "运动"), ("phone", "通讯"), ("desktopcomputer", "数码"),
    ]

    // 常用颜色候选
    private let colorOptions: [String] = [
        "FF9500", "5856D6", "FF2D55", "AF52DE",
        "34C759", "FF3B30", "5AC8FA", "4CD964",
        "007AFF", "FFD93D", "FF6B6B", "4ECDC4",
    ]

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationView {
            Form {
                Section("分类名称") {
                    TextField("如：餐饮、娱乐、健身", text: $name)
                }

                Section("类型") {
                    Picker("类型", selection: $type) {
                        Text("支出").tag(TransactionType.expense)
                        Text("收入").tag(TransactionType.income)
                    }
                    .pickerStyle(.segmented)
                }

                Section("图标") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(iconOptions, id: \.icon) { option in
                            Button {
                                selectedIcon = option.icon
                            } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: option.icon)
                                        .font(.system(size: 22))
                                        .foregroundColor(
                                            selectedIcon == option.icon
                                                ? Color(hex: selectedColorHex) ?? .blue
                                                : .gray
                                        )
                                        .frame(width: 44, height: 44)
                                        .background(
                                            selectedIcon == option.icon
                                                ? (Color(hex: selectedColorHex) ?? .blue).opacity(0.15)
                                                : Color(.systemGray6)
                                        )
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(
                                                    selectedIcon == option.icon
                                                        ? (Color(hex: selectedColorHex) ?? .blue)
                                                        : Color.clear,
                                                    lineWidth: 1.5
                                                )
                                        )
                                    Text(option.label)
                                        .font(.system(size: 9))
                                        .foregroundColor(.secondary)
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
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 2)
                                            .opacity(selectedColorHex == hex ? 1 : 0)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(Color(hex: hex) ?? .blue, lineWidth: 2)
                                            .opacity(selectedColorHex == hex ? 1 : 0)
                                            .padding(2)
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
                            .foregroundColor(Color(hex: selectedColorHex) ?? .blue)
                        Text(name.isEmpty ? "分类名称" : name)
                            .foregroundColor(name.isEmpty ? .secondary : .primary)
                        Spacer()
                        Text(type == .expense ? "支出" : "收入")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("新增分类")
            .navigationBarItems(
                leading: Button("取消") { dismiss() },
                trailing: Button("保存") {
                    let newCat = Category(
                        name: name.trimmingCharacters(in: .whitespaces),
                        icon: selectedIcon,
                        colorHex: selectedColorHex,
                        type: type,
                        sortOrder: categories.count
                    )
                    modelContext.insert(newCat)
                    dismiss()
                }
                .disabled(!isValid)
            )
        }
    }
}

// MARK: - 编辑分类
struct EditCategoryView: View {
    @Bindable var category: Category
    @Environment(\.modelContext) private var modelContext

    private let iconOptions: [(icon: String, label: String)] = [
        ("fork.knife", "餐饮"), ("car", "交通"), ("bag", "购物"),
        ("gamecontroller", "娱乐"), ("house", "住房"), ("heart", "医疗"),
        ("book", "教育"), ("banknote", "工资"), ("chart.line.uptrend.xyaxis", "理财"),
        ("tag", "其他"), ("gift", "礼物"), ("airplane", "出行"),
        ("fitness.timer", "运动"), ("phone", "通讯"), ("desktopcomputer", "数码"),
    ]

    private let colorOptions: [String] = [
        "FF9500", "5856D6", "FF2D55", "AF52DE",
        "34C759", "FF3B30", "5AC8FA", "4CD964",
        "007AFF", "FFD93D", "FF6B6B", "4ECDC4",
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
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                    ForEach(iconOptions, id: \.icon) { option in
                        Button {
                            category.icon = option.icon
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: option.icon)
                                    .font(.system(size: 22))
                                    .foregroundColor(
                                        category.icon == option.icon
                                            ? category.color : .gray
                                    )
                                    .frame(width: 44, height: 44)
                                    .background(
                                        category.icon == option.icon
                                            ? category.color.opacity(0.15)
                                            : Color(.systemGray6)
                                    )
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(
                                                category.icon == option.icon
                                                    ? category.color : Color.clear,
                                                lineWidth: 1.5
                                            )
                                    )
                                Text(option.label)
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary)
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
                        } label: {
                            Circle()
                                .fill(Color(hex: hex) ?? .blue)
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 2)
                                        .opacity(category.colorHex == hex ? 1 : 0)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(Color(hex: hex) ?? .blue, lineWidth: 2)
                                        .opacity(category.colorHex == hex ? 1 : 0)
                                        .padding(2)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 8)
            }

            Section("预览") {
                HStack {
                    Image(systemName: category.icon)
                        .foregroundColor(category.color)
                    Text(category.name.isEmpty ? "分类名称" : category.name)
                        .foregroundColor(category.name.isEmpty ? .secondary : .primary)
                    Spacer()
                    Text(category.type == .expense ? "支出" : "收入")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("编辑分类")
        .navigationBarTitleDisplayMode(.inline)
    }
}