//
//  VoiceManager.swift
//  Demo GPT API
//
//  Created by Tung Dao Thanh on 15/8/25.
//

import UIKit
import Foundation
import Speech
import AVFoundation

extension Notification.Name {
    static let micStateChanged = Notification.Name("micStateChanged")
}

class VoiceManager: NSObject, AVSpeechSynthesizerDelegate {
        
    static let shared = VoiceManager()

    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognizer: SFSpeechRecognizer?
    private var task: SFSpeechRecognitionTask?

    private var synthesizer = AVSpeechSynthesizer()
    var isListening = false
    
    // Timer: 10s chờ bắt đầu nói, 3s im lặng sau khi bắt đầu
    private var startSpeakingTimer: Timer?
    private var silenceTimer: Timer?
    
    private var isStoppedByTimeout = false
    
    // Giữ lại transcript cuối cùng
    private var lastTranscript: String?
    
    private let loi_mo_dau:String = "Xin chào, tôi có thể giúp gì cho bạn"
    
    private let loi_tiep_tuc:String = "Mời bạn nói"
        
    // Các lệnh dừng app
    private let stopCommands: [String] = [
        "dừng lại",
        "thoát ứng dụng",
        "dừng ứng dụng",
        "dừng trợ lý"
    ]
    
    private let cameraCommands: [String] = [
        "mô tả xung quanh tôi",
        "mô tả xung quanh",
        "tả xung quanh",
        "xung quanh",
        "xung quanh tôi",
        "tả xung quanh tôi",
        "có gì xung quanh",
    ]
    
    private let timeCommands: [String] = [
        "bây giờ là mấy giờ",
        "giờ là mấy giờ",
        "là mấy giờ",
        "mấy giờ rồi",
    ]
    
    private let dateCommands: [String] = [
        "hôm nay là ngày nào",
        "hôm nay là ngày mấy",
        "hôm nay là thứ mấy",
        "nay là ngày nào",
    ]
    
    private let lunaCommands: [String] = [
        "lịch âm hôm nay là ngày nào",
        "âm lịch hôm nay là ngày nào",
        "lịch âm là ngày nào",
        "âm lịch là ngày nào",
        "âm lịch là ngày mấy",
        "lịch âm là ngày mấy",
        "âm lịch",
    ]
    
//    private let callCommands: [String] = [
//        "gọi điện thoại",
//        "điện thoại",
//    ]
    
    private let guideCommands: [String] = [
        "hướng dẫn sử dụng",
        "đọc hướng dẫn",
        "hướng dẫn",
        "dẫn sử dụng",
        "sử dụng",
        "sử dụng như nào",
    ]
    
    private let speedIncreaseCommands: [String] = [
        "tăng tốc độ đọc",
        "tăng tốc độ",
    ]
    
    private let speedDecraseCommands: [String] = [
        "giảm tốc độ đọc",
        "giảm tốc độ",
    ]

    
    private var timeoutCount = 0
    private var maxTimeoutCount = StringResources.default_time_out_count
    
    var isManuallyStopped = false

    // Completion cho announce
    private var announceCompletion: (() -> Void)?

    // Lưu lịch sử hội thoại
    private var conversationHistory: [[String: String]] = []

    // Reset toàn bộ hội thoại
    func resetConversation() {
        conversationHistory.removeAll()
        print("🧹 Đã reset lịch sử hội thoại")
    }

    override init() {
        super.init()
        synthesizer.delegate = self
        recognizer = SFSpeechRecognizer(locale: Locale(identifier: "vi-VN"))
    }

    func resetSynthesizer() {
        synthesizer.stopSpeaking(at: .immediate)
        synthesizer = AVSpeechSynthesizer()
        synthesizer.delegate = self
    }
    
    func startListening(startApp: Bool = true) {
        print("startListening is called")
                
        UIApplication.shared.isIdleTimerDisabled = true

        if isListening {
            stopAll() // reset hẳn trước
        }

        isListening = true
        isStoppedByTimeout = false
        isManuallyStopped = false
        lastTranscript = nil

        // Huỷ timer cũ (nếu còn)
        startSpeakingTimer?.invalidate()
        startSpeakingTimer = nil
        silenceTimer?.invalidate()
        silenceTimer = nil

        NotificationCenter.default.post(
            name: .micStateChanged,
            object: nil,
            userInfo: ["isListening": true]
        )

        SFSpeechRecognizer.requestAuthorization { status in
            guard status == .authorized else {
                self.announce("Không có quyền nhận dạng giọng nói")
                self.isListening = false
                return
            }
            // 🔊 Đọc lời mời trước
            if(startApp){
                self.announce(self.loi_mo_dau)
            }
            else{
                self.announce(self.loi_tiep_tuc)
            }
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        // Gọi completion nếu có
        announceCompletion?()
        announceCompletion = nil

        // ✅ vẫn giữ logic cũ: nếu đọc xong lời mời → startRecording()
        if utterance.speechString == loi_mo_dau || utterance.speechString == loi_tiep_tuc {
            DispatchQueue.main.async {
                // ✅ Chỉ startRecording nếu app vẫn active + còn ở trạng thái lắng nghe
                if UIApplication.shared.applicationState == .active, self.isListening {
                    do {
                        try self.startRecording()
                    } catch {
                        self.announce("Không thể khởi động micro")
                        self.isListening = false
                    }
                } else {
                    print("❌ Bỏ qua startRecording vì app không active hoặc đã stop")
                }
            }
        }
    }
    
    func speak(_ text: String, completion: (() -> Void)? = nil) {
        announce(text, completion: completion)
    }
    
    func stopSpeaking() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .word)
        }
    }
    
    private func announce(_ text: String, completion: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            print("announce: \(text)")
            UIAccessibility.post(notification: .announcement, argument: text)
            
            // 🔄 Reset AudioSession để chắc chắn có tiếng
            do {
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
                try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
                try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            } catch {
                print("❌ Failed to reset audio session: \(error)")
            }

            // 🔄 Nếu đang đọc thì dừng ngay
            if self.synthesizer.isSpeaking {
                self.synthesizer.stopSpeaking(at: .immediate)
            }

            self.announceCompletion = completion

            // 🔹 Lấy tốc độ đọc từ UserDefaults (mặc định 0.5)
            let savedRate = UserDefaults.standard.float(forKey: StringResources.key_speechRate)
            let rate = (savedRate > 0) ? savedRate : StringResources.default_speak_rate

            // 🔹 Lấy danh sách giọng tiếng Việt
            let voices = AVSpeechSynthesisVoice.speechVoices().filter { $0.language.hasPrefix("vi") }

            // 🔹 Lấy index giọng từ UserDefaults
            let voiceIndex = SettingsViewController.usd_getInt(
                for: StringResources.key_speechVoice,
                default: 0
            )

            // 🔹 Chọn giọng, nếu index out of range thì fallback giọng đầu tiên
            let selectedVoice: AVSpeechSynthesisVoice
            if voiceIndex >= 0 && voiceIndex < voices.count {
                selectedVoice = voices[voiceIndex]
            } else {
                selectedVoice = AVSpeechSynthesisVoice(language: "vi-VN")!
            }

            // 🔹 Tạo utterance
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = selectedVoice
            utterance.rate = rate

            // 🔊 Đọc
            self.synthesizer.speak(utterance)
        }
    }

    func stopListening() {
        print("stopListening called")

        // Ngắt timer
        silenceTimer?.invalidate()
        silenceTimer = nil

        // Ngắt audio engine
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        request?.endAudio()
        task?.cancel()
        task = nil
        request = nil

        // Reset state
        isListening = false

    }
        
    // Dừng toàn bộ: mic + timer + TTS + reset đếm timeout
    func stopAll(announceStop: Bool = false, resetConver: Bool = true) {
        print("stopAll called")
        
        UIApplication.shared.isIdleTimerDisabled = false

        isManuallyStopped = true  // 🔴 đánh dấu là dừng chủ động

        // dừng nghe (không announce ở đây để tránh chồng lời)
        stopListening()

        // dừng đọc ngay lập tức
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        announceCompletion = nil

        // reset state
        timeoutCount = 0
        isListening = false
        
        if(resetConver){
            resetConversation()
        }
        
        NotificationCenter.default.post(
            name: .micStateChanged,
            object: nil,
            userInfo: ["isListening": false]
        )

        if announceStop {
            announce("Đã dừng trợ lý giọng nói")
        }
    }

    // Public API để ViewController gọi đọc 1 câu và nhận completion khi đọc xong

    private func startRecording() throws {
        print("startRecording")

        task?.cancel()
        request = SFSpeechAudioBufferRecognitionRequest()
        request?.shouldReportPartialResults = true

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .measurement,
                                     options: [.duckOthers, .allowBluetooth, .defaultToSpeaker])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            self.request?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        // ✅ 10s chờ bắt đầu nói (nếu chưa nói gì)
        startSpeakingTimer?.invalidate()
        startSpeakingTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            print("Start-speaking timeout 10s: user chưa nói gì")
            if (self.isManuallyStopped) {
                print("nhay vao timeout nhung da goi isManuallyStopped true")
                return
            }
            self.isStoppedByTimeout = true
            // Dừng thu âm trước khi thông báo
            self.stopListening()
            // Tăng bộ đếm timeout chuỗi
            self.timeoutCount += 1
            
            print("timeoutCount = \(self.timeoutCount)")
            
            if self.timeoutCount >= self.maxTimeoutCount {
                self.announce("Bạn đã yên lặng quá lâu, trợ lý sẽ dừng lại") {
                    self.stopAll(announceStop: false)
                }
            } else {
                print ("startSpeakingTimer timeout")
                self.announce("Không nhận được câu hỏi") {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.startListening(startApp: false)
                    }
                }
            }
        }

        task = recognizer?.recognitionTask(with: request!) { [weak self] result, error in
            guard let self = self else { return }

            if let nsError = error as NSError? {
                if self.isStoppedByTimeout {
                    // ❌ Bỏ qua error giả khi timeout, đã xử lý bằng timer
                    print("finish by timeout (bỏ qua error) \(nsError.domain) \(nsError.code)")
                    return
                }else if self.isManuallyStopped {
                    print("Recognition stopped manually, bỏ qua error")
                    return
                }else {
                    // ✅ Thật sự lỗi
                    print("Recognition error: \(nsError.domain) \(nsError.code) - \(nsError.localizedDescription)")
                    self.announce("Có lỗi khi nhận dạng giọng nói, vui lòng khởi động lại ứng dụng")
                    self.stopAll()
                    return
                }
            }

            guard let result = result else { return }

            let transcript = result.bestTranscription.formattedString
            print("Nội dung nói: \(transcript) | đã xong: \(result.isFinal)")

            if !transcript.isEmpty {
                self.lastTranscript = transcript

                // Người dùng đã bắt đầu nói → huỷ timer 10s và chuyển sang đếm im lặng 3s
                if self.startSpeakingTimer != nil {
                    self.startSpeakingTimer?.invalidate()
                    self.startSpeakingTimer = nil
                }
                // ✅ Mỗi lần có partial → reset 3s để không cắt ngang khi đang nói
                self.resetSilenceTimer()
            }

            if result.isFinal {
                print("Nội dung cuối cùng: \(transcript)")
                self.stopListening()
                self.handleRecognizedText(transcript)
            }
        }

        // ❌ Trước đây gọi resetSilenceTimer() ngay tại đây → gây timeout 3s dù user chưa nói.
        // ĐÃ BỎ để tuân thủ: 10s chờ bắt đầu nói, sau khi có tiếng nói mới đếm 3s im lặng.
    }

    private func resetSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            print("Silence timeout 3s → finishRecognitionAfterTimeout")
            self.isStoppedByTimeout = true
            self.finishRecognitionAfterTimeout()
        }
    }

    private func finishRecognitionAfterTimeout() {
        
        maxTimeoutCount = SettingsViewController.usd_getInt(for: StringResources.key_time_out, default: StringResources.default_time_out_count)
        
        if isManuallyStopped { return }
        
        request?.endAudio()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if self.isListening {
                self.stopListening()
                
                if let transcript = self.lastTranscript, !transcript.isEmpty {
                    print("Final text (timeout): \(transcript)")
                    self.handleRecognizedText(transcript)
                } else {
                    // tăng số lần timeout
                    self.timeoutCount += 1
                    if self.timeoutCount >= self.maxTimeoutCount {
                        // quá nhiều lần im lặng -> stop hẳn
                        self.announce("Bạn đã im lặng quá lâu, trợ lý sẽ dừng lại") {
                            self.stopAll()
                        }
                    } else {
                        // bình thường -> thông báo và quay lại vòng lặp
                        self.announce("Không nhận được câu hỏi") {
                            print ("finishRecognitionAfterTimeout")
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                self.startListening(startApp: false)
                            }
                        }
                    }
                }
            }
        }
    }

    private func handleRecognizedText(_ text: String) {
        
        timeoutCount = 0

        let lower = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        if stopCommands.contains(lower) {
            self.announce("Đã dừng trợ lý giọng nói") {
                self.stopAll()
            }
            return
        }
        
        if cameraCommands.contains(where: { lower.contains($0) }) {
            self.announce("Mở tính năng nhận dạng") {
                
                self.stopAll()
                
                self.delegate?.didRequestOpenCamera()

            }
            return
        }
        
//        if callCommands.contains(lower) {
//            
//            let phone_number = SettingsViewController.usd_getString(for: StringResources.key_phone_number, default: StringResources.default_phone_number)
//
//            self.announce("Tôi sẽ mở màn hình cuộc gọi đến số \(phone_number), bạn cần bấm nút gọi cách phía dưới màn hình 2 centimet để gọi và đưa điện thoại lên sát tai để giao tiếp.") {
//                
//                self.stopAll()
//                
//                if let phoneURL = URL(string: "tel://\(phone_number)") {
//                    if UIApplication.shared.canOpenURL(phoneURL) {
//                        UIApplication.shared.open(phoneURL, options: [:], completionHandler: nil)
//                    } else {
//                        print("Không thể mở URL gọi điện")
//                    }
//                }
//
//            }
//            return
//        }
        
        if timeCommands.contains(where: { lower.contains($0) }) {
            
            self.stopAll()

            let now = Date()
            let cal = Calendar.current
            let h = cal.component(.hour, from: now)
            let m = cal.component(.minute, from: now)

            let date_string = "Bây giờ là \(h) giờ \(m) phút"
            self.announce(date_string) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.startListening(startApp: false)
                }
            }
            return
        }
        
        if dateCommands.contains(lower) {
            
            self.stopAll()

            let now = Date()
            let cal = Calendar.current
            let d = cal.component(.day, from: now)
            let mo = cal.component(.month, from: now)
            let y = cal.component(.year, from: now)
            
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "vi_VN")
            formatter.dateFormat = "EEEE"   // hoặc "EEEE, dd/MM/yyyy"

            let weekdayString = formatter.string(from: now)
            
            let date_string = "Hôm nay là \(weekdayString) \(d) tháng \(mo) năm \(y)"
            self.announce(date_string) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.startListening(startApp: false)
                }
            }
            return
        }
        
        if lunaCommands.contains(lower) {
            
            self.stopAll()

            self.announce("Hôm nay là " + getLunarDateString() + " âm lịch") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.startListening(startApp: false)
                }
            }
            return
        }
        
        if guideCommands.contains(lower) {
            self.announce(StringResources.huong_dan_su_dung) {
                self.stopAll(resetConver: false)

                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.startListening(startApp: false)
                }
            }
            return
        }
        
        if speedDecraseCommands.contains(lower) {
            
            var result: String = ""

            var speed = SettingsViewController.usd_getFloat(for: StringResources.key_speechRate, default: StringResources.default_speak_rate)
            if (speed - AVSpeechUtteranceMinimumSpeechRate > 0.11){
                speed = speed - 0.1
                UserDefaults.standard.set(speed, forKey: StringResources.key_speechRate)
                print("Speed is \(speed)")
                
                result = "Đã giảm tốc độ đọc"

            }else {
                result = "Tốc độ đọc đã chậm nhất"
            }

            self.announce(result) {
                
                self.stopAll()

                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.startListening(startApp: false)
                }
            }
            return
        }
        
        if speedIncreaseCommands.contains(lower) {
            
            var result: String = ""
            
            var speed = SettingsViewController.usd_getFloat(for: StringResources.key_speechRate, default: StringResources.default_speak_rate)
            if (AVSpeechUtteranceMaximumSpeechRate - speed > 0.1){
                speed = speed + 0.1
                UserDefaults.standard.set(speed, forKey: StringResources.key_speechRate)
                print("Speed is \(speed)")
                result = "Đã tăng tốc độ đọc"
            }else {
                result = "Tốc độ đọc đã nhanh nhất"
            }
            
            self.announce(result) {
                
                self.stopAll()

                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.startListening(startApp: false)
                }
            }
            return
        }


        // Bước 1: Nói trước "Đang tìm câu trả lời"
        self.announce("Đang tìm câu trả lời") {
            
            self.stopAll(resetConver: false)

            let startTime = Date()

            //demo trên điện thoại thì gọi trực tiếp
//            self.generateQuote(forMood: text) { quote in
//                let elapsed = Date().timeIntervalSince(startTime)
//                let delay = max(0, 2 - elapsed)  // đảm bảo tối thiểu 2s
//
//                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
//                    self.announce(quote ?? "Xin lỗi, tôi chưa có câu trả lời") {
//                        // ⏳ Sau khi nói xong thì quay lại vòng lặp
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//                            self.startListening(startApp: false)
//                        }
//                    }
//                }
//            }
            
            //triển hhai thực tế gọi backend
            self.askBackend(newQuestion: text) { answer in
                print("Trả lời từ backend: \(String(describing: answer))")
                let elapsed = Date().timeIntervalSince(startTime)
                let delay = max(0, 2 - elapsed)  // đảm bảo tối thiểu 2s

                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    self.announce(answer ?? "Xin lỗi, tôi chưa có câu trả lời") {
                        // ⏳ Sau khi nói xong thì quay lại vòng lặp
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            self.startListening(startApp: false)
                        }
                    }
                }
            }
            
        }
    }

//    func generateQuote(forMood newQuestion: String, completion: @escaping (String?) -> Void) {
//        // 1) Thêm câu hỏi mới của user vào lịch sử
//        conversationHistory.append(["role": "user", "content": newQuestion])
//
//        // 2) Ghép toàn bộ hội thoại thành 1 prompt
//        var fullContext = "Trả lời ngắn gọn, không quá 100 từ. "
//        for msg in conversationHistory {
//            if msg["role"] == "user" {
//                fullContext += "Người dùng: \(msg["content"]!)\n"
//            } else if msg["role"] == "assistant" {
//                fullContext += "Trợ lý: \(msg["content"]!)\n"
//            }
//        }
//        fullContext += "\nTrợ lý:"
//
//        // 👉 GPT-5 dùng /responses thay vì /chat/completions
//        let endpoint = URL(string: "https://api.openai.com/v1/responses")!
//        var request = URLRequest(url: endpoint)
//        request.httpMethod = "POST"
//        request.addValue("Bearer \(StringResources.GPT_KEY)", forHTTPHeaderField: "Authorization")
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//
//        // Body format cho /responses
//        let body: [String: Any] = [
//            "model": "gpt-5-mini",
//            "input": [
//                ["role": "user", "content": fullContext]
//            ],
////            "max_output_tokens": 300
//        ]
//
//        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
//
//        URLSession.shared.dataTask(with: request) { data, _, _ in
//            guard let data = data else {
//                completion(nil)
//                return
//            }
//
//            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
//                completion(nil)
//                return
//            }
//
//            // 1) Ưu tiên field output_text (nếu có)
//            if let outputText = json["output_text"] as? String, !outputText.isEmpty {
//                let text = outputText.trimmingCharacters(in: .whitespacesAndNewlines)
//                self.conversationHistory.append(["role": "assistant", "content": text])
//                completion(text)
//                return
//            }
//
//            // 2) Nếu không có, duyệt output[].content[].text
//            if let outputs = json["output"] as? [[String: Any]] {
//                for item in outputs {
//                    if let contents = item["content"] as? [[String: Any]] {
//                        for content in contents {
//                            if let text = content["text"] as? String {
//                                let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
//                                self.conversationHistory.append(["role": "assistant", "content": cleaned])
//                                completion(cleaned)
//                                return
//                            }
//                        }
//                    }
//                }
//            }
//
//            // 3) Không parse được → trả nil
//            completion(nil)
//        }.resume()
//    }

    func askBackend(newQuestion: String, completion: @escaping (String?) -> Void) {
        
//        guard NetworkMonitor.shared.isConnected else {
//            print("❌ Không có kết nối internet")
//            completion("Không có kết nối internet. Vui lòng kiểm tra lại.")
//            return
//        }
        
        // 1) Thêm câu hỏi mới của user vào lịch sử
        conversationHistory.append(["role": "user", "content": newQuestion])

        // 2) Ghép toàn bộ hội thoại thành 1 prompt
//        var fullContext = "Hãy nhớ ngữ cảnh trước đó để trả lời chính xác. Luôn trả lời ngắn gọn, súc tích, không quá 50 từ."
        var fullContext = "Trả lời ngắn gọn, không quá 100 từ. "

        for msg in conversationHistory {
            if msg["role"] == "user" {
                fullContext += "Người dùng: \(msg["content"]!)\n"
            } else if msg["role"] == "assistant" {
                fullContext += "Trợ lý: \(msg["content"]!)\n"
            }
        }
        fullContext += "\nTrợ lý:"
        
        print("toàn bộ nội dung gửi tới backend: \(fullContext)")

        // 3) Gửi request tới backend
        guard let url = URL(string: StringResources.url_gpt_new) else {
            print("❌ URL không hợp lệ")
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["question": fullContext]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        // 4) Gọi API
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Lỗi gọi backend:", error)
                completion(nil)
                return
            }

            guard let data = data else {
                print("❌ Không nhận được dữ liệu từ backend")
                completion(nil)
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("✅ JSON trả về:", json)

                    // ⚡ Check remaining
                    if let remaining = json["remaining"] as? Int, remaining == 0 {
                        let message = "Bạn đã dùng hết lượt câu hỏi ây ai ngày hôm nay"
                        completion(message)
                        return
                    }

                    if let answer = json["answer"] as? String {
                        // 5) Lưu câu trả lời vào lịch sử
                        self.conversationHistory.append(["role": "assistant", "content": answer])
                        completion(answer)
                    } else {
                        print("⚠️ Không tìm thấy field 'answer'")
                        completion(nil)
                    }
                } else {
                    print("❌ Không parse được JSON từ backend")
                    completion(nil)
                }
            } catch {
                print("❌ Lỗi parse JSON:", error)
                completion(nil)
            }
        }.resume()
    }
    
    func getLunarDateString(from date: Date = Date()) -> String {
        // Lấy thứ dương
        let solarFormatter = DateFormatter()
        solarFormatter.locale = Locale(identifier: "vi_VN")
        solarFormatter.dateFormat = "EEEE"  // ví dụ: "Thứ Năm"
        let weekday = solarFormatter.string(from: date)

        // Lấy ngày âm
        let chineseCalendar = Calendar(identifier: .chinese)
        let comps = chineseCalendar.dateComponents([.day, .month, .year], from: date)

        if let day = comps.day, let month = comps.month, let year = comps.year {
            return "ngày \(day) tháng \(month)"
        }
        return ""
    }

    weak var delegate: VoiceManagerDelegate?

}
protocol VoiceManagerDelegate: AnyObject {
    func didRequestOpenCamera()
}
