import SwiftUI
import SwiftData
import Speech
import AVFoundation

struct DashboardView: View {
    @Query private var transactions: [Transaction]
    @Query private var categories: [Category]

    // 全局主题状态（由 ExpenseTrackerApp 根节点注入）
    @EnvironmentObject var themeSettings: ThemeSettings

    @State private var selectedInputTab: InputTabType = .voice

    // 接收来自 ContentView 的加号按钮绑定（toolbar 统一管理）
    @Binding var showingAddTransaction: Bool

    var currentMonthTransactions: [Transaction] {
        let now = Date()
        let calendar = Calendar.current
        let currentMonth = calendar.dateComponents([.month, .year], from: now)
        return transactions.filter { t in
            let td = calendar.dateComponents([.month, .year], from: t.date)
            return td.month == currentMonth.month
                && td.year == currentMonth.year
                && t.type == .expense
        }
    }

    var recentTransactions: [Transaction] {
        Array(currentMonthTransactions
            .sorted { $0.date > $1.date }
            .prefix(5))
    }

    var totalExpense: Double {
        currentMonthTransactions.reduce(0) { $0 + $1.amount }
    }

    var currentMonthString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月"
        return formatter.string(from: Date())
    }

    var themeColors: ThemeColorSet {
        ThemeManager.getColorSet(isDark: themeSettings.isDarkMode)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                themeColors.backgroundPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppTheme.spacingLarge) {

                        // MARK: - 数据卡片
                        VStack(spacing: AppTheme.spacingMedium) {
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
                            }
                            .padding(.horizontal, AppTheme.spacingLarge)
                            .padding(.top, AppTheme.spacingLarge)

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

                        // MARK: - 输入方式 Tab
                        VStack(spacing: AppTheme.spacingMedium) {
                            HStack(spacing: 0) {
                                ForEach(InputTabType.allCases, id: \.self) { tab in
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.2)) { selectedInputTab = tab }
                                    }) {
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
                                                    gradient: Gradient(colors: [
                                                        themeColors.backgroundSecondary,
                                                        themeColors.backgroundSecondary
                                                    ]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                        )
                                        .foregroundColor(selectedInputTab == tab ? .white : themeColors.textSecondary)
                                        .cornerRadius(AppTheme.cornerRadiusMedium)
                                    }
                                }
                            }
                            .padding(.horizontal, AppTheme.spacingLarge)

                            if selectedInputTab == .voice {
                                VoiceInputView(categories: categories, themeColors: themeColors)
                            } else {
                                TextInputView(categories: categories, themeColors: themeColors)
                            }
                        }

                        // MARK: - 最近账单
                        VStack(spacing: AppTheme.spacingMedium) {
                            HStack {
                                Text("最近账单")
                                    .font(.system(size: AppTheme.fontSizeMedium, weight: .semibold))
                                    .foregroundColor(themeColors.textPrimary)
                                Spacer()
                                // 修复：跳转到真正的 TransactionListView
                                NavigationLink(destination: TransactionListView()) {
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

                        Spacer(minLength: AppTheme.spacingXLarge)
                    }
                    .padding(.bottom, AppTheme.spacingLarge)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // 修复：两个按钮统一放在 toolbar，从左到右：主题切换 → 加号
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    // 深色/浅色模式切换（使用全局 ThemeSettings）
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            themeSettings.isDarkMode.toggle()
                        }
                    }) {
                        Image(systemName: themeSettings.isDarkMode ? "sun.max.fill" : "moon.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(themeColors.primaryColor)
                    }

                    // 新建账单
                    Button(action: { showingAddTransaction = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(themeColors.primaryColor)
                    }
                }
            }
        }
    }
}

// MARK: - 语音输入视图
struct VoiceInputView: View {
    let categories: [Category]
    let themeColors: ThemeColorSet
    @Environment(\.modelContext) private var modelContext

    @State private var isRecording = false
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    @State private var recognizedText = ""
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var audioEngine: AVAudioEngine?
    @State private var speechRecognizer: SFSpeechRecognizer?

    var body: some View {
        VStack(spacing: AppTheme.spacingXLarge) {
            VStack(spacing: AppTheme.spacingLarge) {

                // 修复：移除空 Button 外壳，直接在 ZStack 上挂 DragGesture
                // 原写法 Button(action:{}) 会吞掉 tap，导致长按手势失效
                ZStack {
                    Circle()
                        .fill(isRecording ? themeColors.errorColor.opacity(0.3) : themeColors.glowColor)
                        .frame(
                            width: isRecording ? 180 : 160,
                            height: isRecording ? 180 : 160
                        )
                        .animation(
                            isRecording
                                ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true)
                                : .default,
                            value: isRecording
                        )

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
                .frame(maxWidth: .infinity, alignment: .center)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in if !isRecording { requestPermissionsAndStart() } }
                        .onEnded { _ in stopRecording() }
                )

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
            Button("确定", role: .cancel) {}
        } message: { Text(errorMessage) }
    }

    private func requestPermissionsAndStart() {
        recognizedText = ""
        if speechRecognizer == nil {
            speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
        }
        guard let speechRecognizer = speechRecognizer else {
            showError("您的设备不支持中文语音识别")
            return
        }
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                if authStatus == .authorized {
                    AVAudioSession.sharedInstance().requestRecordPermission { granted in
                        DispatchQueue.main.async {
                            if granted { startRecording() } else { showError("需要麦克风权限") }
                        }
                    }
                } else { showError("需要语音识别权限") }
            }
        }
    }

    private func startRecording() {
        if audioEngine == nil { audioEngine = AVAudioEngine() }
        guard let audioEngine = audioEngine, !audioEngine.isRunning else {
            if audioEngine?.isRunning == true { stopRecording() }
            return
        }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch { showError("无法启动麦克风模块"); return }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
            isRecording = true
        } catch { showError("音频引擎启动失败"); return }

        guard let sr = speechRecognizer else { showError("语音识别器不可用"); return }
        recognitionTask = sr.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result { self.recognizedText = result.bestTranscription.formattedString }
            if error != nil { self.showError("语音识别出错，请重试"); self.stopRecording() }
        }
    }

    private func stopRecording() {
        isRecording = false
        if let audioEngine = audioEngine, audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
            recognitionRequest?.endAudio()
        }
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        if !recognizedText.isEmpty { saveVoiceTransaction(text: recognizedText) }
    }

    private func saveVoiceTransaction(text: String) {
        let amount = extractAmount(from: text) ?? 0.0
        guard amount > 0 else {
            recognizedText = "⚠️ 未听到明确金额：\(text)"
            return
        }
        guard let category = categories.first(where: { $0.name == "餐饮" }) ?? categories.first else {
            showError("无法保存：分类信息不完整")
            return
        }
        let transaction = Transaction(
            amount: amount, date: Date(), note: text, type: .expense, category: category
        )
        modelContext.insert(transaction)
        recognizedText = "✅ 记账成功：提取金额 ¥\(String(format: "%.2f", amount))"
    }

    private func extractAmount(from text: String) -> Double? {
        let regex = try? NSRegularExpression(pattern: "([0-9]+(?:\\.[0-9]+)?)", options: [])
        if let match = regex?.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range(at: 1), in: text) {
            return Double(String(text[range]))
        }
        return nil
    }

    private func showError(_ msg: String) {
        errorMessage = msg
        showingErrorAlert = true
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
        guard !amount.isEmpty, let v = Double(amount) else { return false }
        return v > 0
    }

    func saveTransaction() {
        guard let amountValue = Double(amount), amountValue > 0 else {
            errorMessage = "请输入有效的金额（必须大于0）"
            showingErrorAlert = true
            return
        }
        guard let category = selectedCategory ?? categories.first else {
            errorMessage = "分类信息不完整，无法保存"
            showingErrorAlert = true
            return
        }
        let transaction = Transaction(
            amount: amountValue, date: Date(),
            note: note.isEmpty ? nil : note,
            type: .expense, category: category
        )
        modelContext.insert(transaction)
        amount = ""
        selectedCategory = nil
        note = ""
    }

    var body: some View {
        VStack(spacing: AppTheme.spacingLarge) {
            VStack(spacing: AppTheme.spacingMedium) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("金额").font(.system(size: AppTheme.fontSizeSmall, weight: .semibold)).foregroundColor(themeColors.textSecondary)
                    TextField("0.00", text: $amount)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(themeColors.textPrimary)
                        .padding(AppTheme.spacingMedium)
                        .background(themeColors.backgroundSecondary)
                        .cornerRadius(AppTheme.cornerRadiusMedium)
                        .overlay(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium).stroke(themeColors.borderColor, lineWidth: 1))
                        .onChange(of: amount) { oldValue, newValue in
                            let filtered = newValue.filter { $0.isNumber || $0 == "." }
                            let components = filtered.split(separator: ".", omittingEmptySubsequences: false)
                            amount = components.count > 2 ? oldValue : filtered
                        }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("分类").font(.system(size: AppTheme.fontSizeSmall, weight: .semibold)).foregroundColor(themeColors.textSecondary)
                    Picker("分类", selection: $selectedCategory) {
                        Text("未分类").tag(nil as Category?)
                        ForEach(categories) { cat in
                            HStack {
                                Image(systemName: cat.icon)
                                Text(cat.name)
                            }.tag(cat as Category?)
                        }
                    }
                    .frame(maxWidth: .infinity).frame(height: 44)
                    .background(themeColors.backgroundSecondary)
                    .cornerRadius(AppTheme.cornerRadiusMedium)
                    .overlay(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium).stroke(themeColors.borderColor, lineWidth: 1))
                }
                .onAppear {
                    if selectedCategory == nil && !categories.isEmpty {
                        selectedCategory = categories.first
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("备注（可选）").font(.system(size: AppTheme.fontSizeSmall, weight: .semibold)).foregroundColor(themeColors.textSecondary)
                    TextField("添加备注...", text: $note)
                        .font(.system(size: AppTheme.fontSizeMedium))
                        .foregroundColor(themeColors.textPrimary)
                        .padding(AppTheme.spacingMedium)
                        .frame(height: 44)
                        .background(themeColors.backgroundSecondary)
                        .cornerRadius(AppTheme.cornerRadiusMedium)
                        .overlay(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium).stroke(themeColors.borderColor, lineWidth: 1))
                }

                Button(action: saveTransaction) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill").font(.system(size: 16, weight: .semibold))
                        Text("记一笔").font(.system(size: AppTheme.fontSizeMedium, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity).frame(height: 48)
                    .background(
                        isAmountValid
                            ? LinearGradient(gradient: Gradient(colors: [themeColors.primaryColor, themeColors.accentColor]), startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(gradient: Gradient(colors: [themeColors.borderColor, themeColors.borderColor]), startPoint: .topLeading, endPoint: .bottomTrailing)
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
            Button("确定") {}
        } message: { Text(errorMessage) }
    }
}

// MARK: - 最近账单行
struct TransactionRowItem: View {
    let transaction: Transaction
    let themeColors: ThemeColorSet

    var typeColor: Color {
        transaction.type == .income ? themeColors.successColor : themeColors.errorColor
    }

    var body: some View {
        HStack(spacing: AppTheme.spacingMedium) {
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.note ?? "未命名记录")
                    .font(.system(size: AppTheme.fontSizeMedium, weight: .semibold))
                    .foregroundColor(themeColors.textPrimary)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Image(systemName: transaction.category.icon).font(.system(size: 12))
                    Text(transaction.category.name).font(.system(size: AppTheme.fontSizeSmall))
                }
                .foregroundColor(transaction.category.color)
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
    case voice, text
    var label: String { self == .voice ? "语音输入" : "文本输入" }
    var icon: String  { self == .voice ? "mic"      : "pencil"  }
}