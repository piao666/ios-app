import SwiftUI

struct TextInputView: View {
    @State private var title: String = ""
    @State private var amount: String = ""

    var body: some View {
        Form {
            TextField("消费名称（必填）", text: $title)
            TextField("金额", text: $amount)
            Button(action: saveTransaction) {
                Text("保存")
            }
        }
    }

    private func saveTransaction() {
        // Save transaction logic with title and amount
    }
}