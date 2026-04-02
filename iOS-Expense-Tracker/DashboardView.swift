import SwiftUI

struct DashboardView: View {
    var body: some View {
        ScrollView {
            LazyVStack(pinnedViews: [.sectionHeaders]) {
                Section(header: Text("概览与总支出")) {
                    // 概览与总支出卡片
                }
                Section {
                    // 输入区和账单列表
                }
            }
        }
        .navigationTitle("Dashboard")
    }
}