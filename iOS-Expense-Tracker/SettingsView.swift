import SwiftUI

struct SettingsView: View {
    // 假设 Category 已经在其他地方定义，这里用假数据测试 UI
    @State private var categories: [Category] = [] 

    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(categories, id: \.self) { category in
                        NavigationLink(destination: Text("编辑分类：\(category.name)")) {
                            Text(category.name)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: deleteCategory)
                    .onMove(perform: moveCategory)
                } footer: {
                    Button(action: {
                        // 执行添加新分类的逻辑
                    }) {
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
                // 必须加这个 EditButton，列表的排序功能才能生效
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
        }
    }

    private func deleteCategory(offsets: IndexSet) {
        categories.remove(atOffsets: offsets)
    }

    private func moveCategory(from source: IndexSet, to destination: Int) {
        categories.move(fromOffsets: source, toOffset: destination)
    }
}