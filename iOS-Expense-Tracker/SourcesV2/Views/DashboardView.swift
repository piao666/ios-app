import AVFoundation
import Speech
import SwiftData
import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var themeSettings: ThemeSettings
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @Query(sort: \Category.sortOrder) private var categories: [Category]

    @Binding var showingAddTransaction: Bool
    @State private var selectedInputTab: InputTabType = .voice

    private var themeColors: ThemeColorSet {
        ThemeManager.getColorSet(isDark: themeSettings.isDarkMode)
    }

    private var monthTransactions: [Transaction] {
        let calendar = Calendar.current
        return transactions.filter {
            calendar.isDate($0.date, equalTo: Date(), toGranularity: .month)
        }
    }

    private var monthExpense: Double {
        monthTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }

    private var monthIncome: Double {
        monthTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }

    private var recentTransactions: [Transaction] {
        Array(transactions.prefix(5))
    }

    private var currentMonthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: Date())
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppTheme.spacingLarge) {
                summarySection
                quickInputSection
                recentSection
            }
            .padding(.horizontal, AppTheme.spacingLarge)
            .padding(.top, AppTheme.spacingMedium)
            .padding(.bottom, AppTheme.spacingXXLarge)
        }
        .background(themeColors.backgroundPrimary.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 8) {
                    Image("BrandLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 22, height: 22)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    Text("小海帐")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(themeColors.textPrimary)
                }
            }

            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        themeSettings.toggle()
                    }
                } label: {
                    Image(systemName: themeSettings.isDarkMode ? "sun.max.fill" : "moon.stars.fill")
                        .foregroundStyle(themeColors.primaryColor)
                }

                Button {
                    showingAddTransaction = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(themeColors.primaryColor)
                }
            }
        }
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingLarge) {
            VStack(alignment: .leading, spacing: AppTheme.spacingXSmall) {
                Text("总览")
                    .font(.system(size: AppTheme.fontSizeTitle, weight: .bold))
                    .foregroundStyle(themeColors.textPrimary)
                Text(currentMonthTitle)
                    .font(.system(size: AppTheme.fontSizeBody, weight: .medium))
                    .foregroundStyle(themeColors.textSecondary)
            }

            HStack(spacing: AppTheme.spacingMedium) {
                DashboardMetricCard(
                    title: "本月收入",
                    value: monthIncome.formatted(.currency(code: "CNY")),
                    tint: themeColors.successColor,
                    themeColors: themeColors
                )

                DashboardMetricCard(
                    title: "本月支出",
                    value: monthExpense.formatted(.currency(code: "CNY")),
                    tint: themeColors.errorColor,
                    themeColors: themeColors
                )
            }

            DashboardBalanceCard(
                balance: monthIncome - monthExpense,
                count: monthTransactions.count,
                themeColors: themeColors
            )
        }
        .padding(AppTheme.spacingLarge)
        .background(
            LinearGradient(
                colors: [themeColors.heroTopColor, themeColors.heroBottomColor],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge)
                .stroke(themeColors.cardBorder, lineWidth: 1)
        )
    }

    private var quickInputSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMedium) {
            Text("快捷记账")
                .font(.system(size: AppTheme.fontSizeSubtitle, weight: .bold))
                .foregroundStyle(themeColors.textPrimary)

            HStack(spacing: AppTheme.spacingSmall) {
                ForEach(InputTabType.allCases) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedInputTab = tab
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: tab.icon)
                            Text(tab.title)
                        }
                        .font(.system(size: AppTheme.fontSizeBody, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selectedInputTab == tab ? themeColors.primaryColor : themeColors.chipBackground)
                        .foregroundStyle(selectedInputTab == tab ? Color.white : themeColors.textSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
                    }
                    .buttonStyle(.plain)
                }
            }

            Group {
                if selectedInputTab == .voice {
                    VoiceInputView(categories: categories, themeColors: themeColors)
                } else {
                    TextQuickEntryView(categories: categories, themeColors: themeColors)
                }
            }
            .padding(AppTheme.spacingLarge)
            .background(themeColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge)
                    .stroke(themeColors.cardBorder, lineWidth: 1)
            )
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMedium) {
            HStack {
                Text("最近交易")
                    .font(.system(size: AppTheme.fontSizeSubtitle, weight: .bold))
                    .foregroundStyle(themeColors.textPrimary)
                Spacer()
                NavigationLink("查看全部") {
                    TransactionListView()
                }
                .font(.system(size: AppTheme.fontSizeBody, weight: .semibold))
                .foregroundStyle(themeColors.primaryColor)
            }

            if recentTransactions.isEmpty {
                VStack(spacing: AppTheme.spacingSmall) {
                    Image(systemName: "tray")
                        .font(.system(size: 28))
                        .foregroundStyle(themeColors.textTertiary)
                    Text("还没有交易记录")
                        .font(.system(size: AppTheme.fontSizeBody, weight: .medium))
                        .foregroundStyle(themeColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(AppTheme.spacingXXLarge)
                .background(themeColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge)
                        .stroke(themeColors.cardBorder, lineWidth: 1)
                )
            } else {
                VStack(spacing: AppTheme.spacingSmall) {
                    ForEach(recentTransactions, id: \.id) { transaction in
                        NavigationLink {
                            TransactionDetailView(transaction: transaction)
                        } label: {
                            DashboardTransactionRow(transaction: transaction, themeColors: themeColors)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

private struct DashboardMetricCard: View {
    let title: String
    let value: String
    let tint: Color
    let themeColors: ThemeColorSet

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: AppTheme.fontSizeCaption, weight: .medium))
                .foregroundStyle(themeColors.textSecondary)

            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(tint)
                .minimumScaleFactor(0.72)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.spacingMedium)
        .background(themeColors.cardBackground.opacity(0.94))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium))
    }
}

private struct DashboardBalanceCard: View {
    let balance: Double
    let count: Int
    let themeColors: ThemeColorSet

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("本月结余")
                .font(.system(size: AppTheme.fontSizeCaption, weight: .medium))
                .foregroundStyle(themeColors.textSecondary)
            Text(balance.formatted(.currency(code: "CNY")))
                .font(.system(size: AppTheme.fontSizeHero, weight: .bold))
                .foregroundStyle(themeColors.primaryColor)
                .minimumScaleFactor(0.72)
                .lineLimit(1)
            Text("本月共 \(count) 笔记录")
                .font(.system(size: AppTheme.fontSizeCaption))
                .foregroundStyle(themeColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.spacingLarge)
        .background(themeColors.cardBackground.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium))
    }
}

private struct DashboardTransactionRow: View {
    let transaction: Transaction
    let themeColors: ThemeColorSet

    var body: some View {
        HStack(spacing: AppTheme.spacingMedium) {
            Circle()
                .fill(transaction.category.color.opacity(0.16))
                .frame(width: 48, height: 48)
                .overlay {
                    Image(systemName: transaction.category.icon)
                        .foregroundStyle(transaction.category.color)
                        .font(.system(size: 18, weight: .semibold))
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.displayTitle)
                    .font(.system(size: AppTheme.fontSizeBody, weight: .semibold))
                    .foregroundStyle(themeColors.textPrimary)
                    .lineLimit(1)

                Text(transaction.date.formatted(date: .numeric, time: .shortened))
                    .font(.system(size: AppTheme.fontSizeCaption))
                    .foregroundStyle(themeColors.textSecondary)
            }

            Spacer()

            Text(transaction.signedAmountText)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(transaction.type.color)
        }
        .padding(AppTheme.spacingMedium)
        .background(themeColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)
                .stroke(themeColors.cardBorder, lineWidth: 1)
        )
    }
}

struct VoiceInputView: View {
    @Environment(\.modelContext) private var modelContext

    let categories: [Category]
    let themeColors: ThemeColorSet

    @State private var isRecording = false
    @State private var recognizedText = ""
    @State private var statusText = "点下面的按钮开始语音记账，例如：午饭 32 元"
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""

    @State private var audioEngine = AVAudioEngine()
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))

    var body: some View {
        VStack(spacing: AppTheme.spacingLarge) {
            Button {
                isRecording ? stopRecording(saveResult: true) : requestPermissionsAndStart()
            } label: {
                ZStack {
                    Circle()
                        .fill((isRecording ? themeColors.errorColor : themeColors.primaryColor).opacity(0.16))
                        .frame(width: 138, height: 138)

                    Circle()
                        .fill(isRecording ? themeColors.errorColor : themeColors.primaryColor)
                        .frame(width: 94, height: 94)

                    Image(systemName: isRecording ? "waveform" : "mic.fill")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(.plain)

            VStack(spacing: 10) {
                Text(isRecording ? "正在聆听，再点一次即可结束" : "语音记账")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(themeColors.textPrimary)

                Text(recognizedText.isEmpty ? statusText : recognizedText)
                    .font(.system(size: AppTheme.fontSizeBody))
                    .foregroundStyle(recognizedText.isEmpty ? themeColors.textSecondary : themeColors.primaryColor)
                    .multilineTextAlignment(.center)
            }

            if !recognizedText.isEmpty {
                Text("停止录音后会自动尝试识别金额、分类和收支类型。")
                    .font(.system(size: AppTheme.fontSizeCaption))
                    .foregroundStyle(themeColors.textTertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .alert("语音记账失败", isPresented: $showingErrorAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    @MainActor
    private func requestPermissionsAndStart() {
        recognizedText = ""
        guard !isRecording else { return }

        guard speechRecognizer != nil else {
            showError("当前设备不支持中文语音识别。")
            return
        }

        SFSpeechRecognizer.requestAuthorization { status in
            guard status == .authorized else {
                Task { @MainActor in
                    showError("请先打开语音识别权限。")
                }
                return
            }

            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                Task { @MainActor in
                    guard granted else {
                        showError("请先打开麦克风权限。")
                        return
                    }
                    startRecording()
                }
            }
        }
    }

    @MainActor
    private func startRecording() {
        recognitionTask?.cancel()
        recognitionTask = nil

        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            showError("无法启动录音：\(error.localizedDescription)")
            return
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputNode.outputFormat(forBus: 0)) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()

        do {
            try audioEngine.start()
            isRecording = true
            statusText = "正在识别你的语音…"
        } catch {
            showError("录音启动失败：\(error.localizedDescription)")
            return
        }

        recognitionTask = speechRecognizer?.recognitionTask(with: request) { result, error in
            Task { @MainActor in
                if let result {
                    recognizedText = result.bestTranscription.formattedString
                }

                if error != nil {
                    stopRecording(saveResult: false)
                    showError("语音识别发生错误，请重试。")
                }
            }
        }
    }

    @MainActor
    private func stopRecording(saveResult: Bool) {
        isRecording = false

        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil

        guard saveResult, !recognizedText.isEmpty else {
            return
        }

        saveRecognizedTransaction()
    }

    @MainActor
    private func saveRecognizedTransaction() {
        guard let amount = extractAmount(from: recognizedText), amount > 0 else {
            showError("没有识别到有效金额，请说得更明确一点。")
            return
        }

        let type: TransactionType = incomeKeywords.contains(where: { recognizedText.contains($0) }) ? .income : .expense

        guard let category = matchCategory(from: recognizedText, type: type) else {
            showError("没有可用分类，请先在设置里添加分类。")
            return
        }

        let transaction = Transaction(
            amount: amount,
            date: Date(),
            note: recognizedText,
            type: type,
            category: category
        )

        modelContext.insert(transaction)
        try? modelContext.save()
        statusText = "识别完成，已经自动生成一笔记录。"
    }

    private func matchCategory(from text: String, type: TransactionType) -> Category? {
        let keywordMap: [String: [String]] = [
            "餐饮": ["饭", "餐", "咖啡", "奶茶", "早餐", "午餐", "晚餐", "外卖"],
            "交通": ["地铁", "公交", "打车", "高铁", "交通", "油费"],
            "购物": ["买", "购物", "淘宝", "京东", "超市", "商场"],
            "娱乐": ["电影", "唱歌", "游戏", "娱乐", "门票"],
            "住房": ["房租", "物业", "住房", "水电"],
            "医疗": ["医院", "药", "看病", "体检"],
            "教育": ["书", "课程", "学费", "培训"],
            "工资": ["工资", "发薪", "薪资"],
            "理财": ["基金", "理财", "收益", "分红", "利息"]
        ]

        for category in categories where category.type == type {
            let keywords = keywordMap[category.name] ?? []
            if keywords.contains(where: { text.contains($0) }) {
                return category
            }
        }

        return categories.first { $0.type == type } ?? categories.first
    }

    private func extractAmount(from text: String) -> Double? {
        let pattern = "([0-9]+(?:\\.[0-9]+)?)"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(text.startIndex..., in: text)

        guard
            let match = regex?.firstMatch(in: text, range: range),
            let valueRange = Range(match.range(at: 1), in: text)
        else {
            return nil
        }

        return Double(String(text[valueRange]))
    }

    @MainActor
    private func showError(_ message: String) {
        errorMessage = message
        showingErrorAlert = true
    }

    private var incomeKeywords: [String] {
        ["工资", "报销", "收益", "奖金", "分红", "收入"]
    }
}

struct TextQuickEntryView: View {
    @Environment(\.modelContext) private var modelContext

    let categories: [Category]
    let themeColors: ThemeColorSet

    @State private var amount = ""
    @State private var note = ""
    @State private var type: TransactionType = .expense
    @State private var selectedCategoryID: UUID?
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""

    private var availableCategories: [Category] {
        let matching = categories.filter { $0.type == type }
        return matching.isEmpty ? categories : matching
    }

    var body: some View {
        VStack(spacing: AppTheme.spacingMedium) {
            HStack(spacing: AppTheme.spacingSmall) {
                ForEach(TransactionType.allCases) { currentType in
                    Button {
                        type = currentType
                        selectedCategoryID = availableCategories.first?.id
                    } label: {
                        Text(currentType.rawValue)
                            .font(.system(size: AppTheme.fontSizeBody, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(type == currentType ? currentType.color : themeColors.backgroundPrimary)
                            .foregroundStyle(type == currentType ? Color.white : themeColors.textSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
                    }
                    .buttonStyle(.plain)
                }
            }

            DashboardInputField(title: "金额", text: $amount, placeholder: "输入金额")
                .keyboardType(.decimalPad)

            VStack(alignment: .leading, spacing: 6) {
                Text("分类")
                    .font(.system(size: AppTheme.fontSizeCaption, weight: .medium))
                    .foregroundStyle(themeColors.textSecondary)

                Picker("分类", selection: $selectedCategoryID) {
                    ForEach(availableCategories, id: \.id) { category in
                        Text(category.name).tag(Optional(category.id))
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AppTheme.spacingMedium)
                .padding(.vertical, 12)
                .background(themeColors.backgroundPrimary)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
            }

            DashboardInputField(title: "备注", text: $note, placeholder: "输入备注")

            Button("保存这笔记录") {
                saveTransaction()
            }
            .font(.system(size: AppTheme.fontSizeBody, weight: .bold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(themeColors.primaryColor)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
        }
        .onAppear {
            selectedCategoryID = availableCategories.first?.id
        }
        .onChange(of: type) { _, _ in
            selectedCategoryID = availableCategories.first?.id
        }
        .alert("保存失败", isPresented: $showingErrorAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private func saveTransaction() {
        guard let amountValue = Double(amount), amountValue > 0 else {
            errorMessage = "请输入大于 0 的有效金额。"
            showingErrorAlert = true
            return
        }

        guard let category = availableCategories.first(where: { $0.id == selectedCategoryID }) ?? availableCategories.first else {
            errorMessage = "请先创建分类。"
            showingErrorAlert = true
            return
        }

        let transaction = Transaction(
            amount: amountValue,
            date: Date(),
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            type: type,
            category: category
        )

        modelContext.insert(transaction)
        try? modelContext.save()

        amount = ""
        note = ""
        selectedCategoryID = availableCategories.first?.id
    }
}

private struct DashboardInputField: View {
    let title: String
    @Binding var text: String
    let placeholder: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: AppTheme.fontSizeCaption, weight: .medium))
                .foregroundStyle(.secondary)
            TextField(placeholder, text: $text)
                .font(.system(size: AppTheme.fontSizeBody, weight: .medium))
                .padding(.horizontal, AppTheme.spacingMedium)
                .padding(.vertical, 12)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
        }
    }
}
