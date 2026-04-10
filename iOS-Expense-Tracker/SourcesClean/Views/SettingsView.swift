import SwiftData
import SwiftUI

private let categoryIconOptions = [
    "fork.knife",
    "car.fill",
    "bag.fill",
    "house.fill",
    "heart.fill",
    "book.fill",
    "gamecontroller.fill",
    "gift.fill",
    "airplane",
    "creditcard.fill"
]

private let categoryColorOptions = [
    "2563EB",
    "16A34A",
    "DB2777",
    "F97316",
    "DC2626",
    "7C3AED",
    "0F766E",
    "D97706"
]

struct SettingsView: View {
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @State private var showingAddCategory = false

    var body: some View {
        List {
            Section {
                ForEach(categories, id: \.id) { category in
                    NavigationLink {
                        EditCategoryView(category: category)
                    } label: {
                        HStack(spacing: AppTheme.mediumSpacing) {
                            Circle()
                                .fill(category.color)
                                .frame(width: 34, height: 34)
                                .overlay(
                                    Image(systemName: category.icon)
                                        .foregroundStyle(.white)
                                )
                            VStack(alignment: .leading, spacing: 2) {
                                Text(category.name)
                                Text(category.type.rawValue)
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.mutedText)
                            }
                        }
                    }
                }
            } header: {
                Text("Categories")
            } footer: {
                Button("Add category") {
                    showingAddCategory = true
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showingAddCategory) {
            NavigationStack {
                AddCategoryView()
            }
        }
    }
}

struct AddCategoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.sortOrder) private var categories: [Category]

    @State private var name = ""
    @State private var icon = categoryIconOptions[0]
    @State private var colorHex = categoryColorOptions[0]
    @State private var type: TransactionType = .expense

    var body: some View {
        Form {
            Section {
                TextField("Name", text: $name)
            } header: {
                Text("Name")
            }

            Section {
                Picker("Type", selection: $type) {
                    ForEach(TransactionType.allCases) { transactionType in
                        Text(transactionType.rawValue).tag(transactionType)
                    }
                }
                .pickerStyle(.segmented)
            } header: {
                Text("Type")
            }

            Section {
                IconPickerGrid(selectedIcon: $icon, colorHex: colorHex)
            } header: {
                Text("Icon")
            }

            Section {
                ColorPickerGrid(selectedColorHex: $colorHex)
            } header: {
                Text("Color")
            }
        }
        .navigationTitle("New Category")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    let category = Category(
                        name: trimmedName,
                        icon: icon,
                        colorHex: colorHex,
                        type: type,
                        sortOrder: categories.count
                    )
                    modelContext.insert(category)
                    try? modelContext.save()
                    dismiss()
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
}

struct EditCategoryView: View {
    @Bindable var category: Category
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Form {
            Section {
                TextField("Name", text: $category.name)
            } header: {
                Text("Name")
            }

            Section {
                Picker("Type", selection: $category.type) {
                    ForEach(TransactionType.allCases) { transactionType in
                        Text(transactionType.rawValue).tag(transactionType)
                    }
                }
                .pickerStyle(.segmented)
            } header: {
                Text("Type")
            }

            Section {
                IconPickerGrid(selectedIcon: $category.icon, colorHex: category.colorHex)
            } header: {
                Text("Icon")
            }

            Section {
                ColorPickerGrid(selectedColorHex: $category.colorHex)
            } header: {
                Text("Color")
            }
        }
        .navigationTitle("Edit Category")
        .onDisappear {
            try? modelContext.save()
        }
    }
}

private struct IconPickerGrid: View {
    @Binding var selectedIcon: String
    let colorHex: String

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: AppTheme.mediumSpacing) {
            ForEach(categoryIconOptions, id: \.self) { option in
                Button {
                    selectedIcon = option
                } label: {
                    Image(systemName: option)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.smallRadius)
                                .fill(selectedIcon == option ? (Color(hex: colorHex) ?? AppTheme.primaryColor).opacity(0.18) : AppTheme.cardBackground)
                        )
                        .foregroundStyle(selectedIcon == option ? (Color(hex: colorHex) ?? AppTheme.primaryColor) : AppTheme.mutedText)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, AppTheme.smallSpacing)
    }
}

private struct ColorPickerGrid: View {
    @Binding var selectedColorHex: String

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: AppTheme.mediumSpacing) {
            ForEach(categoryColorOptions, id: \.self) { option in
                Button {
                    selectedColorHex = option
                } label: {
                    Circle()
                        .fill(Color(hex: option) ?? AppTheme.primaryColor)
                        .frame(width: 34, height: 34)
                        .overlay(
                            Circle()
                                .stroke(Color.primary, lineWidth: selectedColorHex == option ? 2 : 0)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, AppTheme.smallSpacing)
    }
}
