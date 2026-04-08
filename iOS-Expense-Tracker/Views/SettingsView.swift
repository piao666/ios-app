import SwiftUI
import SwiftData

struct SettingsView: View {
    // 接入真实的数据库查询，并按 sortOrder 排序
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(categories) { category in
                        NavigationLink(destination: Text("编辑分类：\(category.name)")) {
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
                    Button(action: {
                        // TODO: 弹出添加分类表单 (后续 S3 完善)
                        print("点击了添加新分类")
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
        }
    }

    // 真正的 SwiftData 删除逻辑
    private func deleteCategory(offsets: IndexSet) {
        for index in offsets {
            let categoryToDelete = categories[index]
            modelContext.delete(categoryToDelete)
        }
    }

    // 真正的 SwiftData 拖拽排序逻辑，通过更新 sortOrder 实现持久化
    private func moveCategory(from source: IndexSet, to destination: Int) {
        var revisedItems: [Category] = categories.map { $0 }
        revisedItems.move(fromOffsets: source, toOffset: destination)
        
        // 遍历更新所有的 sortOrder 以保存到数据库
        for reverseIndex in stride(from: revisedItems.count - 1, through: 0, by: -1) {
            revisedItems[reverseIndex].sortOrder = reverseIndex
        }
    }
}