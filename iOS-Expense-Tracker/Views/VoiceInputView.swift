import SwiftUI
import Speech
import AVFoundation

struct VoiceInputView: View {
    @State private var isRecording = false
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    
    private let audioEngine = AVAudioEngine()
    // 修正语言为中文
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))

    var body: some View {
        ZStack {
            if isRecording {
                Circle().fill(Color.red)
                Text("录音中...").foregroundColor(.white)
            } else {
                Circle().fill(Color.gray)
                Text("按住 说话").foregroundColor(.white)
            }
        }
        .frame(width: 100, height: 100)
        .gesture(
            // 使用 minimumDistance: 0 完美模拟“按下”和“抬起”
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
    }

    // 处理权限请求
    private func requestPermissionsAndStart() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                if authStatus == .authorized {
                    AVAudioSession.sharedInstance().requestRecordPermission { granted in
                        DispatchQueue.main.async {
                            if granted {
                                startRecording()
                            } else {
                                print("麦克风权限被拒绝")
                            }
                        }
                    }
                } else {
                    print("语音识别权限被拒绝")
                }
            }
        }
    }

    // 开始录音并识别
    private func startRecording() {
        if audioEngine.isRunning {
            stopRecording()
            return
        }

        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("音频会话配置失败: \(error)")
            return
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, _) in
            recognitionRequest.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
            isRecording = true
        } catch {
            print("音频引擎启动失败: \(error)")
            return
        }

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                // 打印出实时的识别结果，后续可对接给文本框
                print("识别结果: \(result.bestTranscription.formattedString)")
            }
            if error != nil {
                self.stopRecording()
            }
        }
    }

    // 停止录音
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
    }
}