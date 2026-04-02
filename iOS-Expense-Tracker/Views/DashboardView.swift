import SwiftUI
import SwiftData
import Speech
import AVFoundation

struct DashboardView: View {
    @Query private var transactions: [Transaction]
    @Query private var categories: [Category]
    @Environment(\.colorScheme) var colorScheme

    @State private var isDarkMode: Bool = false
    @State private var selectedInputTab: InputTabType = .voice

    var currentMonthTransactions: [Transaction] {
        let now = Date()
        let calendar = Calendar.current
        let currentMonth = calendar.dateComponents([.month, .year], from: now)

        return transactions.filter { transaction in
            let transactionDate = calendar.dateComponents([.month, .year], from: transaction.date)
            return transactionDate.month == currentMonth.month && transactionDate.year == currentMonth.year && transaction.type == .expense
        }
    }

    var recentTransactions: [Transaction] {
        currentMonthTransactions
            .sorted { $0.date > $1.date }
            .prefix(5)
            .reversed()
    }

    var totalExpense: Double {
        currentMonthTransactions.reduce(0) { $0 + $1.amount }
    }

    var currentMonthString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY年MM月"
        return formatter.string(from: Date())
    }

    var themeColors: ThemeColorSet {
        ThemeManager.getColorSet(isDark: isDarkMode)
    }

    var body: some View {
        ZStack {
            // 动态背景
            themeColors.backgroundPrimary.ignoresSafeArea()

            VStack(spacing: AppTheme.spacingLarge) {
                // MARK: - 顶部卡片 + 主题切换按钮
                VStack(spacing: AppTheme.spacingMedium) {
                    // 月份 + 主题切换按钮
                    HStack {
                        VStack(alignment: .leading, spacing: AppTheme.spacingSmall) {
                            Text("概览")
                                .font(.system(size: AppTheme.fontSizeTitle, weight: .bold))
                                .foregroundColor(themeColors.textPrimary)

                            Text(currentMonthString)
                                .font(.system(size: AppTheme.fontSizeLarge, weight: .medium))
                                .foregroundColor(themeColors.textSecondary)
                        }

                        Spacer()

                        // 主题切换按钮
                        Button(action: { withAnimation(.easeInOut(duration: 0.3)) { isDarkMode.toggle() } }) {
                            Image(systemName: isDarkMode ? "sun.max.fill" : "moon.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(themeColors.primaryColor)
                                .frame(width: 44, height: 44)
                                .background(themeColors.backgroundSecondary)
                                .cornerRadius(AppTheme.cornerRadiusMedium)
                        }
                    }
                    .padding(AppTheme.spacingLarge)

                    // 本月总支出卡片
                    VStack(spacing: AppTheme.spacingMedium) {
                        HStack {
                            VStack(alignment: .leading, spacing: AppTheme.spacingSmall) {
                                Text("本月总支出")
                                    .font(.system(size: AppTheme.fontSizeMedium, weight: .medium))
                                    .foregroundColor(themeColors.textSecondary)

                                Text("¥\(String(format: "%.2f", totalExpense))")
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(themeColors.primaryColor)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: AppTheme.spacingSmall) {
                                Text("交易笔数")
                                    .font(.system(size: AppTheme.fontSizeMedium, weight: .medium))
                                    .foregroundColor(themeColors.textSecondary)

                                Text("\(currentMonthTransactions.count)")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(themeColors.textPrimary)
                            }
                        }
                        .padding(AppTheme.spacingLarge)
                    }
                    .background(themeColors.backgroundSecondary)
                    .cornerRadius(AppTheme.cornerRadiusLarge)
                    .padding(.horizontal, AppTheme.spacingLarge)
                }

                // MARK: - 输入方式 Tab 选择
                VStack(spacing: AppTheme.spacingMedium) {
                    // Tab 切换器
                    HStack(spacing: 0) {
                        ForEach(InputTabType.allCases, id: \.self) { tab in
                            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { selectedInputTab = tab } }) {
                                HStack(spacing: 6) {
                                    Image(systemName: tab.icon)
                                        .font(.system(size: 14, weight: .semibold))
                                    Text(tab.label)
                                        .font(.system(size: AppTheme.fontSizeMedium, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(
                                    selectedInputTab == tab
                                        ? LinearGradient(
                                            gradient: Gradient(colors: [
                                                themeColors.primaryColor.opacity(0.8),
                                                themeColors.accentColor.opacity(0.6)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                        : LinearGradient(
                                            gradient: Gradient(colors: [themeColors.backgroundSecondary, themeColors.backgroundSecondary]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                )
                                .foregroundColor(selectedInputTab == tab ? .white : themeColors.textSecondary)
                                .cornerRadius(AppTheme.cornerRadiusMedium)
                            }
                        }
                    }
                    .padding(AppTheme.spacingLarge)

                    // Tab 内容
                    if selectedInputTab == .voice {
                        // 语音输入视图
                        VoiceInputView(themeColors: themeColors)
                    } else {
                        // 文本输入视图
                        TextInputView(categories: categories, themeColors: themeColors)
                    }
                }
                .padding(.horizontal, AppTheme.spacingLarge)

                // MARK: - 最近账单列表
                VStack(spacing: AppTheme.spacingMedium) {
                    HStack {
                        Text("最近账单")
                            .font(.system(size: AppTheme.fontSizeMedium, weight: .semibold))
                            .foregroundColor(themeColors.textPrimary)

                        Spacer()

                        NavigationLink(destination: Text("全部账单")) {
                            HStack(spacing: 4) {
                                Text("查看全部")
                                    .font(.system(size: AppTheme.fontSizeSmall, weight: .medium))
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundColor(themeColors.primaryColor)
                        }
                    }
                    .padding(.horizontal, AppTheme.spacingLarge)

                    // 最近交易列表
                    if recentTransactions.isEmpty {
                        VStack(spacing: AppTheme.spacingMedium) {
                            Image(systemName: "list.bullet")
                                .font(.system(size: 32))
                                .foregroundColor(themeColors.textTertiary)
                            Text("暂无账单")
                                .font(.system(size: AppTheme.fontSizeMedium, weight: .medium))
                                .foregroundColor(themeColors.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(AppTheme.spacingXLarge)
                    } else {
                        VStack(spacing: AppTheme.spacingSmall) {
                            ForEach(recentTransactions, id: \.id) { transaction in
                                TransactionRowItem(transaction: transaction, themeColors: themeColors)
                            }
                        }
                        .padding(.horizontal, AppTheme.spacingLarge)
                    }
                }

                Spacer()
            }
            .padding(.vertical, AppTheme.spacingLarge)
        }
        .onAppear {
            isDarkMode = colorScheme == .dark
        }
    }
}

// MARK: - 语音输入视图
struct VoiceInputView: View {
    let themeColors: ThemeColorSet
    @Environment(\.modelContext) private var modelContext

    // 语音识别底层状态
    @State private var isRecording = false
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    @State private var recognizedText = ""
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""

    private let audioEngine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))

    var body: some View {
        VStack(spacing: AppTheme.spacingXLarge) {
            VStack(spacing: AppTheme.spacingLarge) {
                // 麦克风按钮 (带手势和录音动画)
                Button(action: {}) {
                    ZStack {
                        // 发光背景圆圈 (录音时变红并呼吸)
                        Circle()
                            .fill(isRecording ? themeColors.errorColor.opacity(0.3) : themeColors.glowColor)
                            .frame(width: isRecording ? 180 : 160, height: isRecording ? 180 : 160)
                            .animation(isRecording ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true) : .default, value: isRecording)

                        // 按钮主体
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        isRecording ? themeColors.errorColor : themeColors.primaryColor,
                                        isRecording ? themeColors.errorColor.opacity(0.8) : themeColors.accentColor
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)

                        Image(systemName: isRecording ? "waveform" : "mic.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if !isRecording {
                                requestPermissionsAndStart()
                            }
                        }
                        .onEnded { _ in
                            stopRecording()
                        }
                )

                // 提示文本区
                VStack(spacing: 8) {
                    Text(isRecording ? "正在聆听..." : "长按说出你的账单")
                        .font(.system(size: AppTheme.fontSizeMedium, weight: .semibold))
                        .foregroundColor(isRecording ? themeColors.errorColor : themeColors.textPrimary)

                    if !recognizedText.isEmpty {
                        Text(recognizedText)
                            .font(.system(size: AppTheme.fontSizeLarge, weight: .bold))
                            .foregroundColor(themeColors.primaryColor)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    } else {
                        Text("例如：早上买咖啡 50 块")
                            .font(.system(size: AppTheme.fontSizeSmall, weight: .regular))
                            .foregroundColor(themeColors.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(AppTheme.spacingXLarge)

            Spacer()
        }
        .alert("权限或识别错误", isPresented: $showingErrorAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - 语音核心逻辑
    private func requestPermissionsAndStart() {
        recognizedText = ""
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                if authStatus == .authorized {
                    AVAudioSession.sharedInstance().requestRecordPermission { granted in
                        DispatchQueue.main.async {
                            if granted {
                                startRecording()
                            } else {
                                showError("记账需要麦克风权限")
                            }
                        }
                    }
                } else {
                    showError("记账需要语音识别权限，请在手机设置中开启")
                }
            }
        }
    }

    private func startRecording() {
        if audioEngine.isRunning { stopRecording(); return }

        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            showError("无法启动麦克风模块")
            return
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.removeTap(onBus: 0) // 防止重复 Tap 导致崩溃
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, _) in
            self.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
            isRecording = true
        } catch {
            showError("音频引擎启动失败")
            return
        }

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                self.recognizedText = result.bestTranscription.formattedString
            }
            if error != nil {
                self.stopRecording()
            }
        }
    }

    private func stopRecording() {
        isRecording = false
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
            recognitionRequest?.endAudio()
        }
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        
        // 录音结束，自动保存到数据库
        if !recognizedText.isEmpty {
            saveVoiceTransaction(text: recognizedText)
        }
    }
    
    // MARK: - 极简智能记账解析
    private func saveVoiceTransaction(text: String) {
        let amountValue = extractAmount(from: text) ?? 0.0
        if amountValue > 0 {
            // 默认分类为餐饮
            let category = Category.defaultCategories.first(where: { $0.name == "餐饮" }) ?? Category.defaultCategories[0]
            
            let transaction = Transaction(
                amount: amountValue,
                date: Date(),
                note: text, // 原话作为备注
                type: .expense,
                category: category
            )
            modelContext.insert(transaction)
            recognizedText = "✅ 记账成功：提取金额 ¥\(amountValue)"
        } else {
            recognizedText = "⚠️ 未听到明确金额：\(text)"
        }
    }

    private func extractAmount(from text: String) -> Double? {
        // 利用正则提取话里的数字（支持小数）
        let regex = try? NSRegularExpression(pattern: "([0-9]+(?:\\.[0-9]+)?)", options: [])
        if let match = regex?.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range(at: 1), in: text) {
            return Double(text[range])
        }
        return nil
    }

    private func showError(_ msg: String) {
        self.errorMessage = msg
        self.showingErrorAlert = true
    }
}

// MARK: - 文本输入视图
struct TextInputView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var amount = ""
    @State private var selectedCategory: Category?
    @State private var note = ""
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""

    let categories: [Category]
    let themeColors: ThemeColorSet

    var isAmountValid: Bool {
        guard !amount.isEmpty else { return false }
        guard let amountValue = Double(amount) else { return false }
        return amountValue > 0
    }

    func saveTransaction() {
        // 验证金额
        guard let amountValue = Double(amount), amountValue > 0 else {
            errorMessage = "请输入有效的金额（必须大于0）"
            showingErrorAlert = true
            return
        }

        // 创建交易记录
        let transaction = Transaction(
            amount: amountValue,
            title: "",  // 如果需要标题，可以添加新的 @State 变量
            note: note.isEmpty ? nil : note,
            type: .expense,
            category: selectedCategory
        )

        // 存入 SwiftData
        modelContext.insert(transaction)

        // 清空输入框
        amount = ""
        selectedCategory = nil
        note = ""
    }

    var body: some View {
        VStack(spacing: AppTheme.spacingLarge) {
            VStack(spacing: AppTheme.spacingMedium) {
                // 金额输入框
                VStack(alignment: .leading, spacing: 6) {
                    Text("金额")
                        .font(.system(size: AppTheme.fontSizeSmall, weight: .semibold))
                        .foregroundColor(themeColors.textSecondary)

                    TextField("0.00", text: $amount)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(themeColors.textPrimary)
                        .padding(AppTheme.spacingMedium)
                        .background(themeColors.backgroundSecondary)
                        .cornerRadius(AppTheme.cornerRadiusMedium)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)
                                .stroke(themeColors.borderColor, lineWidth: 1)
                        )
                        .onChange(of: amount) { oldValue, newValue in
                            // 只允许数字和小数点
                            let filtered = newValue.filter { $0.isNumber || $0 == "." }
                            let components = filtered.split(separator: ".", omittingEmptySubsequences: false)
                            if components.count > 2 {
                                amount = oldValue
                            } else {
                                amount = filtered
                            }
                        }
                }

                // 分类选择
                VStack(alignment: .leading, spacing: 6) {
                    Text("分类")
                        .font(.system(size: AppTheme.fontSizeSmall, weight: .semibold))
                        .foregroundColor(themeColors.textSecondary)

                    Picker("分类", selection: $selectedCategory) {
                        Text("未分类").tag(nil as Category?)
                        ForEach(categories) { category in
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.name)
                            }
                            .tag(category as Category?)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(themeColors.backgroundSecondary)
                    .cornerRadius(AppTheme.cornerRadiusMedium)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)
                            .stroke(themeColors.borderColor, lineWidth: 1)
                    )
                }

                // 备注输入框
                VStack(alignment: .leading, spacing: 6) {
                    Text("备注（可选）")
                        .font(.system(size: AppTheme.fontSizeSmall, weight: .semibold))
                        .foregroundColor(themeColors.textSecondary)

                    TextField("添加备注...", text: $note)
                        .font(.system(size: AppTheme.fontSizeMedium))
                        .foregroundColor(themeColors.textPrimary)
                        .padding(AppTheme.spacingMedium)
                        .frame(height: 44)
                        .background(themeColors.backgroundSecondary)
                        .cornerRadius(AppTheme.cornerRadiusMedium)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)
                                .stroke(themeColors.borderColor, lineWidth: 1)
                        )
                }

                // 保存按钮
                Button(action: saveTransaction) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text("记一笔")
                            .font(.system(size: AppTheme.fontSizeMedium, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        isAmountValid
                            ? LinearGradient(
                                gradient: Gradient(colors: [
                                    themeColors.primaryColor,
                                    themeColors.accentColor
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                gradient: Gradient(colors: [
                                    themeColors.borderColor,
                                    themeColors.borderColor
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(AppTheme.cornerRadiusMedium)
                }
                .disabled(!isAmountValid)
            }
            .padding(AppTheme.spacingLarge)

            Spacer()
        }
        .alert("输入错误", isPresented: $showingErrorAlert) {
            Button("确定") { }
        } message: {
            Text(errorMessage)
        }
    }
}

// MARK: - 最近账单行项目
struct TransactionRowItem: View {
    let transaction: Transaction
    let themeColors: ThemeColorSet

    var typeColor: Color {
        transaction.type == .income ? themeColors.successColor : themeColors.errorColor
    }

    var body: some View {
        HStack(spacing: AppTheme.spacingMedium) {
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.title)
                    .font(.system(size: AppTheme.fontSizeMedium, weight: .semibold))
                    .foregroundColor(themeColors.textPrimary)

                if let category = transaction.category {
                    HStack(spacing: 4) {
                        Image(systemName: category.icon)
                            .font(.system(size: 12))
                        Text(category.name)
                            .font(.system(size: AppTheme.fontSizeSmall))
                    }
                    .foregroundColor(category.color)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(transaction.type == .income ? "+" : "-")¥\(String(format: "%.2f", transaction.amount))")
                    .font(.system(size: AppTheme.fontSizeMedium, weight: .semibold))
                    .foregroundColor(typeColor)

                Text(transaction.date, style: .date)
                    .font(.system(size: AppTheme.fontSizeSmall))
                    .foregroundColor(themeColors.textTertiary)
            }
        }
        .padding(AppTheme.spacingMedium)
        .background(themeColors.backgroundSecondary)
        .cornerRadius(AppTheme.cornerRadiusMedium)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)
                .stroke(themeColors.borderColor, lineWidth: 0.5)
        )
    }
}

// MARK: - 输入类型枚举
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
    DashboardView()
        .modelContainer(for: [Transaction.self, Category.self], inMemory: true)
}
