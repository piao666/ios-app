import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            // 这里替换为您主界面的真实内容，例如 DashboardView()
            Text("账单概览主界面") 
                .navigationTitle("小海帐")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack(spacing: 16) {
                            Button(action: {
                                // 切换深浅色逻辑
                            }) {
                                Image(systemName: "sun.min.fill")
                            }
                            Button(action: {
                                // 新增记账逻辑
                            }) {
                                Image(systemName: "plus")
                            }
                        }
                    }
                }
        }
    }
}