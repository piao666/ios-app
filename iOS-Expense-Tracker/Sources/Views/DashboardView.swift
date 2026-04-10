import AVFoundation
import Speech
import SwiftData
import SwiftUI

struct DashboardView: View {
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @EnvironmentObject private var themeSettings: ThemeSettings

    @Binding var showingAddTransaction: Bool
    @State private var selectedInputTab: InputTabType = .voice

    private var currentMonthTransactions: [Transaction] {
        let now = Date()
        let calendar = Calendar.current
        let currentMonth = calendar.dateComponents([.month, .year], from: now)

        return transactions.filter { transaction in
            let components = calendar.dateComponents([.month, .year], from: transaction.date)
            return components.month == currentMonth.month
                && components.year == currentMonth.year
                && transaction.type == .expense
        }
    }

    private var recentTransactions: [Transaction] {
        Array(currentMonthTransactions.prefix(5))
    }

    private var totalExpense: Double {
        currentMonthTransactions.reduce(0) { $0 + $1.amount }
    }

    private var currentMonthString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: Date())
    }

    private var themeColors: ThemeColorSet {
        ThemeManager.getColorSet(isDark: themeSettings.isDarkMode)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                themeColors.backgroundPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppTheme.spacingLarge) {
                        summaryCard
                        inputSection
                        recentSection
                    }
                    .padding(.horizontal, AppTheme.spacingLarge)
                    .padding(.vertical, AppTheme.spacingLarge)
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        withAnimation {
                            themeSettings.isDarkMode.toggle()
                        }
                    } label: {
                        Image(systemName: themeSettings.isDarkMode ? "sun.max.fill" : "moon.fill")
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
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMedium) {
            Text("概览")
                .font(.system(size: AppTheme.fontSizeTitle, weight: .bold))
                .foregroundStyle(themeColors.textPrimary)
            Text(currentMonthString)
                .font(.system(size: AppTheme.fontSizeLarge, weight: .medium))
                .foregroundStyle(themeColors.textSecondary)

            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("本月总支出")
                        .font(.subheadline)
                        .foregroundStyle(themeColors.textSecondary)
                    Text("¥\(String(format: "%.2f", totalExpense))")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(themeColors.primaryColor)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Text("交易笔数")
                        .font(.subheadline)
                        .foregroundStyle(themeColors.textSecondary)
                    Text("\(currentMonthTransactions.count)")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(themeColors.textPrimary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.spacingLarge)
        .background(themeColors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge))
    }

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMedium) {
            HStack(spacing: 0) {
                ForEach(InputTabType.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedInputTab = tab
                        }
                    } label: {
                        Label(tab.label, systemImage: tab.icon)
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(selectedInputTab == tab ? themeColors.primaryColor : themeColors.backgroundSecondary)
                            .foregroundStyle(selectedInputTab == tab ? Color.white : themeColors.textSecondary)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium))

            if selectedInputTab == .voice {
                VoiceInputView(categories: categories, themeColors: themeColors)
            } else {
                TextInputView(categories: categories, themeColors: themeColors)
            }
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMedium) {
            HStack {
                Text("最近账单")
                    .font(.headline)
                    .foregroundStyle(themeColors.textPrimary)

                Spacer()

                NavigationLink("查看全部") {
                    TransactionListView()
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(themeColors.primaryColor)
            }

            if recentTransactions.isEmpty {
                VStack(spacing: AppTheme.spacingMedium) {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 32))
                        .foregroundStyle(themeColors.textTertiary)
                    Text("还没有账单记录")
                        .foregroundStyle(themeColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(AppTheme.spacingXLarge)
                .background(themeColors.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge))
            } else {
                VStack(spacing: AppTheme.spacingSmall) {
                    ForEach(recentTransactions) { transaction in
                        TransactionRowItem(transaction: transaction, themeColors: themeColors)
                    }
                }
            }
        }
    }
}

struct VoiceInputView: View {
    let categories: [Category]
    let themeColors: ThemeColorSet

    @Environment(\.modelContext) private var modelContext
    @State private var isRecording = false
    @State private var recognizedText = ""
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var didSaveCurrentRecording = false

    private let audioEngine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?

    var body: some View {
        VStack(spacing: AppTheme.spacingLarge) {
            Button {
                isRecording ? stopRecording(saveResult: true) : requestPermissionsAndStart()
            } label: {
                ZStack {
                    Circle()
                        .fill(isRecording ? themeColors.errorColor.opacity(0.18) : themeColors.glowColor)
                        .frame(width: 168, height: 168)

                    Circle()
                        .fill(isRecording ? themeColors.errorColor : themeColors.primaryColor)
                        .frame(width: 118, height: 118)

                    Image(systemName: isRecording ? "waveform" : "mic.fill")
                        .font(.system(size: 42))
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(.plain)

            VStack(spacing: 8) {
                Text(isRecording ? "正在录音，再点一次结束" : "点按开始语音记账")
                    .font(.headline)
                    .foregroundStyle(isRecording ? themeColors.errorColor : themeColors.textPrimary)

                Text(recognizedText.isEmpty ? "例如：午饭 48 元" : recognizedText)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(recognizedText.isEmpty ? themeColors.textSecondary : themeColors.primaryColor)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.spacingXLarge)
        .background(themeColors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge))
        .alert("语音输入错误", isPresented: $showingErrorAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private func requestPermissionsAndStart() {
        recognizedText = ""
        didSaveCurrentRecording = false

        guard speechRecognizer != nil else {
            showError("当前设备不支持中文语音识别。")
            return
        }

        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                guard status == .authorized else {
                    showError("请先允许语音识别权限。")
                    return
                }

                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    DispatchQueue.main.async {
                        guard granted else {
                            showError("请先允许麦克风权限。")
                            return
                        }
                        startRecording()
                    }
                }
            }
        }
    }

    private func startRecording() {
        recognitionTask?.cancel()
        recognitionTask = nil

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            showError("无法启动麦克风。")
            return
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputNode.outputFormat(forBus: 0)) { buffer, _ in
            recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()

        do {
            try audioEngine.start()
            isRecording = true
        } catch {
            showError("录音引擎启动失败。")
            return
        }

        recognitionTask = speechRecognizer?.recognitionTask(with: request) { result, error in
            if let result {
                recognizedText = result.bestTranscription.formattedString
            }

            if error != nil {
                stopRecording(saveResult: false)
                showError("语音识别失败，请重试。")
            }
        }
    }

    private func stopRecording(saveResult: Bool) {
        guard isRecording || recognitionTask != nil else {
            return
        }

        isRecording = false
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil

        if saveResult, !didSaveCurrentRecording, !recognizedText.isEmpty {
            didSaveCurrentRecording = true
            saveVoiceTransaction(text: recognizedText)
        }
    }

    private func saveVoiceTransaction(text: String) {
        let amount = extractAmount(from: text) ?? 0
        guard amount > 0 else {
            recognizedText = "没有识别到金额：\(text)"
            return
        }

        guard let category = categories.first(where: { $0.type == .expense }) ?? categories.first else {
            showError("请先创建分类后再试。")
            return
        }

        let transaction = Transaction(
            amount: amount,
            date: Date(),
            note: text,
            type: .expense,
            category: category
        )

        modelContext.insert(transaction)
        try? modelContext.save()
        recognizedText = "已保存：¥\(String(format: "%.2f", amount))"
    }

    private func extractAmount(from text: String) -> Double? {
        let regex = try? NSRegularExpression(pattern: "([0-9]+(?:\\.[0-9]+)?)")
        let range = NSRange(text.startIndex..<text.endIndex, in: text)

        guard
            let match = regex?.firstMatch(in: text, options: [], range: range),
            let amountRange = Range(match.range(at: 1), in: text)
        else {
            return nil
        }

        return Double(String(text[amountRange]))
    }

    private func showError(_ message: String) {
        errorMessage = message
        showingErrorAlert = true
    }
}

struct TextInputView: View {
    let categories: [Category]
    let themeColors: ThemeColorSet

    @Environment(\.modelContext) private var modelContext
    @State private var amount = ""
    @State private var selectedCategory: Category?
    @State private var note = ""
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""

    private var isAmountValid: Bool {
        guard let value = Double(amount) else {
            return false
        }
        return value > 0
    }

    var body: some View {
        VStack(spacing: AppTheme.spacingLarge) {
            VStack(alignment: .leading, spacing: 6) {
                Text("金额")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(themeColors.textSecondary)
                TextField("0.00", text: $amount)
                    .keyboardType(.decimalPad)
                    .padding(AppTheme.spacingMedium)
                    .background(themeColors.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)
                            .stroke(themeColors.borderColor, lineWidth: 1)
                    )
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("分类")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(themeColors.textSecondary)
                Picker("分类", selection: $selectedCategory) {
                    Text("未分类").tag(nil as Category?)
                    ForEach(categories) { category in
                        Label(category.name, systemImage: category.icon)
                            .tag(category as Category?)
                    }
                }
                .padding(.horizontal, AppTheme.spacingSmall)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(themeColors.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("备注")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(themeColors.textSecondary)
                TextField("补充说明...", text: $note)
                    .padding(AppTheme.spacingMedium)
                    .background(themeColors.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)
                            .stroke(themeColors.borderColor, lineWidth: 1)
                    )
            }

            Button(action: saveTransaction) {
                Label("记一笔", systemImage: "checkmark.circle.fill")
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(isAmountValid ? themeColors.primaryColor : themeColors.borderColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium))
            }
            .disabled(!isAmountValid)
        }
        .padding(AppTheme.spacingLarge)
        .background(themeColors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge))
        .onAppear {
            if selectedCategory == nil {
                selectedCategory = categories.first(where: { $0.type == .expense }) ?? categories.first
            }
        }
        .alert("输入错误", isPresented: $showingErrorAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private func saveTransaction() {
        guard let amountValue = Double(amount), amountValue > 0 else {
            errorMessage = "请输入有效金额。"
            showingErrorAlert = true
            return
        }

        guard let category = selectedCategory ?? categories.first else {
            errorMessage = "请先创建分类。"
            showingErrorAlert = true
            return
        }

        let transaction = Transaction(
            amount: amountValue,
            date: Date(),
            note: note.isEmpty ? nil : note,
            type: .expense,
            category: category
        )

        modelContext.insert(transaction)
        try? modelContext.save()
        amount = ""
        note = ""
        selectedCategory = categories.first(where: { $0.type == .expense }) ?? categories.first
    }
}

struct TransactionRowItem: View {
    let transaction: Transaction
    let themeColors: ThemeColorSet

    private var typeColor: Color {
        transaction.type == .income ? themeColors.successColor : themeColors.errorColor
    }

    var body: some View {
        HStack(spacing: AppTheme.spacingMedium) {
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.note ?? "未命名记录")
                    .font(.system(size: AppTheme.fontSizeMedium, weight: .semibold))
                    .foregroundStyle(themeColors.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: transaction.category.icon)
                    Text(transaction.category.name)
                }
                .font(.caption)
                .foregroundStyle(transaction.category.color)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(transaction.type == .income ? "+" : "-")¥\(String(format: "%.2f", transaction.amount))")
                    .font(.system(size: AppTheme.fontSizeMedium, weight: .semibold))
                    .foregroundStyle(typeColor)
                Text(transaction.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(themeColors.textTertiary)
            }
        }
        .padding(AppTheme.spacingMedium)
        .background(themeColors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium))
    }
}

enum InputTabType: CaseIterable {
    case voice
    case text

    var label: String {
        switch self {
        case .voice:
            return "语音输入"
        case .text:
            return "文本输入"
        }
    }

    var icon: String {
        switch self {
        case .voice:
            return "mic"
        case .text:
            return "pencil"
        }
    }
}

#Preview {
    DashboardView(showingAddTransaction: .constant(false))
        .modelContainer(Transaction.previewContainer)
        .environmentObject(ThemeSettings())
}
