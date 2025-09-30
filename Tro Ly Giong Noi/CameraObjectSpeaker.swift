//
//  CameraObjectSpeaker.swift
//  Demo GPT API
//
//  Created by Tung Dao Thanh on 27/8/25.
//

import UIKit
import AVFoundation
import Vision
import CoreML
import CoreHaptics

protocol CameraObjectSpeakerDelegate: AnyObject {
    func cameraObjectSpeakerDidFinish(_ controller: CameraObjectSpeaker)
}

final class CameraObjectSpeaker: UIViewController {
    // MARK: - Public
    weak var delegate: CameraObjectSpeakerDelegate?
    
    // MARK: - AV / Vision
    private let captureSession = AVCaptureSession()
    private var videoOutput: AVCaptureVideoDataOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?

    private var vnModel: VNCoreMLModel!
    private var detectionRequest: VNCoreMLRequest!

    // MARK: - TTS & Haptics
    private let speaker = AVSpeechSynthesizer()
    private var hapticEngine: CHHapticEngine?

    // Debounce + Change detection
//    private var lastAnnounceAt = Date.distantPast
//    private let minSpeakInterval: TimeInterval = 1.6
    private var lastSignature = ""   // so sánh thay đổi cảnh

    // Confidence threshold (tăng nhẹ để bớt loạn)
//    private let minConfidence: VNConfidence = 0.55

    // Preview (ẩn cho người mù)
//    private let showPreview: Bool = false

    // Frame throttle để giảm nhấp nháy (xử lý mỗi 2 frame)
    private var frameCount = 0
    private let frameStride = 2
    
    // Debounce & ổn định cảnh
    private var lastAnnounceAt = Date.distantPast
//    private let minSpeakInterval: TimeInterval = 1.8

    // Ổn định: cần lặp lại cùng “cảnh” đủ số frame mới nói
    private var lastSpokenSignature = ""
    private var candidateSignature = ""
    private var stableCounter = 0
//    private let stabilityFramesRequired = 6

    // Lịch sử đếm để làm “chế độ bền vững” (mode) chống rung
    private var countsHistory: [[String:Int]] = []
//    private let countsHistoryLimit = 5

    // Confidence cao hơn để bớt loạn
    private let minConfidence: VNConfidence = 0.6

    // Bật preview để xem trực quan
    private var showPreview: Bool = true
    
    private let countsHistoryLimit = 20
    private let stabilityFramesRequired = 4

    private let minSpeakInterval: TimeInterval = 2.0
    
    private var lastDetectionTime = Date.distantPast
    private let detectionInterval: TimeInterval = 0.4 // 0.3–0.5s tuỳ chỉnh
    private var appStartAt = Date()

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UIApplication.shared.isIdleTimerDisabled = true

        showPreview = ViewController.usd_getBool(for: StringResources.key_camera_preview, default: true)
        view.backgroundColor = .black
        setupModel()
        setupSession()
        setupHaptics()
        addExitTap()
        announce(text:"Đã mở camera")
        appStartAt = Date()   // đánh dấu lúc camera khởi động
    }

    override func viewWillAppear(_ animated: Bool) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopDetection()
    }

    // MARK: - Setup Model
    private func setupModel() {
        do {
            // Chú ý: tên class phải đúng với .mlpackage bạn kéo vào (thường là 'yolov8s')
            let core = try yolov8m(configuration: MLModelConfiguration()).model
            vnModel = try VNCoreMLModel(for: core)
            detectionRequest = VNCoreMLRequest(model: vnModel, completionHandler: handleDetections)
            detectionRequest.imageCropAndScaleOption = .scaleFill
            print("✅ VN model yolov8m ready")
        } catch {
            fatalError("Failed to load model yolov8s: \(error)")
        }
    }

    // MARK: - Camera Session
    private func setupSession() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .high

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else {
            fatalError("No camera available")
        }

        if captureSession.canAddInput(input) { captureSession.addInput(input) }

        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        output.alwaysDiscardsLateVideoFrames = true
        let queue = DispatchQueue(label: "camera.queue")
        output.setSampleBufferDelegate(self, queue: queue)

        if captureSession.canAddOutput(output) { captureSession.addOutput(output); videoOutput = output }

        if let conn = output.connection(with: .video), conn.isVideoOrientationSupported {
            conn.videoOrientation = .portrait
        }

        captureSession.commitConfiguration()

        if showPreview {
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer?.videoGravity = .resizeAspectFill
            previewLayer?.frame = view.bounds
            if let pl = previewLayer { view.layer.insertSublayer(pl, at: 0) }
        }
    }

    // MARK: - Haptics
    private func setupHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        hapticEngine = try? CHHapticEngine()
        try? hapticEngine?.start()
    }

    // MARK: - Exit Tap
    private func addExitTap() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleExitTap))
        tap.numberOfTapsRequired = 1
        view.addGestureRecognizer(tap)
    }

    @objc private func handleExitTap() {
        announce(text: "Tắt mô tả")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.stopDetection()
            self.delegate?.cameraObjectSpeakerDidFinish(self)

        }
    }

    // MARK: - Public stop
    func stopDetection() {
        if captureSession.isRunning { captureSession.stopRunning() }
        speaker.stopSpeaking(at: .immediate)
        if let engine = hapticEngine { try? engine.stop() }
    }

    // MARK: - Detection handling
    private func handleDetections(request: VNRequest, error: Error?) {
        guard let results = request.results as? [VNRecognizedObjectObservation], !results.isEmpty else { return }

        let now = Date()
        guard now.timeIntervalSince(appStartAt) > 1.5 else { return }

        // Lọc theo confidence (giữ nguyên ngưỡng của bạn)
        let filtered = results.compactMap { obs -> VNRecognizedObjectObservation? in
            guard let label = obs.labels.first else { return nil }
            let cls = label.identifier.lowercased()

            if cls.contains("person") {
                // riêng person phải >= 0.65
                guard label.confidence >= 0.65 else { return nil }
            } else {
                // còn lại dùng minConfidence chung
                guard label.confidence >= minConfidence else { return nil }
            }
            return obs
        }
        if filtered.isEmpty { return }

        // Chuẩn hoá item + điểm gần
        struct Item {
            let cls: String
            let bbox: CGRect
            let proxScore: CGFloat   // càng cao càng gần
            let bucket: Int          // 0 rất gần, 1 gần, 2 TB, 3 xa
            var isPerson: Bool { cls.contains("person") }
        }

        func proximityScore(_ b: CGRect) -> CGFloat {
            let h = max(0, min(1, b.height))
            let vertical = 1 - b.midY
            return 0.7 * h + 0.3 * vertical
        }
        
        func distanceBucket(_ b: CGRect) -> Int {
            let h = b.height
            if h >= 0.45 { return 0 }
            if h >= 0.28 { return 1 }
            if h >= 0.15 { return 2 }
            return 3
        }

        let items: [Item] = filtered.map { obs in
            let cls = obs.labels.first!.identifier.lowercased()
            return Item(
                cls: cls,
                bbox: obs.boundingBox,
                proxScore: proximityScore(obs.boundingBox),
                bucket: distanceBucket(obs.boundingBox)
            )
        }

        // Ưu tiên người trước, trong mỗi nhóm sắp xếp theo proxScore giảm dần
        let persons = items.filter { $0.isPerson }.sorted { $0.proxScore > $1.proxScore }
        let others  = items.filter { !$0.isPerson }.sorted { $0.proxScore > $1.proxScore }
        let ordered = Array((persons + others).prefix(20))
        if ordered.isEmpty { return }

        // Đếm số lượng theo cls (tiếng Anh) trong frame hiện tại
        var countsFrame: [String:Int] = [:]
        ordered.forEach { countsFrame[$0.cls, default: 0] += 1 }

        // Lưu lịch sử để lấy mode (giữ nguyên countsHistory và giới hạn)
        countsHistory.append(countsFrame)
        if countsHistory.count > countsHistoryLimit { countsHistory.removeFirst() }

        // Thứ tự nhóm cần đọc (dùng các key tiếng Anh; person ở đầu để ưu tiên đọc)
        let nounsOrderEN = [
            "person","table","chair","bed","door","dog","cat",
            "motorcycle","bicycle","car","tv","cell phone","laptop",
            "umbrella","book","clock","refrigerator"
        ]

        func stabilizedCounts(from history: [[String:Int]]) -> [String:Int] {
            var out: [String:Int] = [:]
            for noun in nounsOrderEN {
                var freq: [Int:Int] = [:]
                for h in history {
                    let v = h[noun] ?? 0
                    freq[v, default: 0] += 1
                }
                if let best = freq.max(by: { (a, b) -> Bool in
                    if a.value == b.value { return a.key > b.key }
                    return a.value < b.value
                }) {
                    out[noun] = best.key
                } else {
                    out[noun] = 0
                }
            }
            return out
        }

        let counts = stabilizedCounts(from: countsHistory)

        // Tạo chữ ký ổn định (giữ nguyên cơ chế signature)
        let stableSignature: String = nounsOrderEN
            .compactMap { n -> String? in
                guard let v = counts[n], v > 0 else { return nil }
                return "\(n):\(v)"
            }
            .joined(separator: ",")

        if stableSignature != candidateSignature {
            candidateSignature = stableSignature
            stableCounter = 1
            return
        } else {
            stableCounter += 1
        }

        guard !stableSignature.isEmpty else { return }
        guard stableSignature != lastSpokenSignature else { return }
        guard stableCounter >= stabilityFramesRequired else { return }
        guard now.timeIntervalSince(lastAnnounceAt) > minSpeakInterval else { return }

        // === Mapping tiếng Anh -> tiếng Việt chỉ ở đây, khi build câu để đọc ===
        func viPhrase(noun: String, count: Int) -> String? {
            switch noun {
            case "person": return "\(count) người"
            case "table": return "\(count) cái bàn"
            case "chair": return "\(count) cái ghế"
            case "bed": return "\(count) cái giường"
            case "door": return "\(count) cái cửa"
            case "dog": return "\(count) con chó"
            case "cat": return "\(count) con mèo"
            case "motorcycle": return "\(count) xe gắn máy"
            case "bicycle": return "\(count) xe đạp"
            case "car": return "\(count) xe ô tô"
            case "tv": return "\(count) ti vi"
            case "cell phone": return "\(count) điện thoại di động"
            case "laptop": return "\(count) máy tính xách tay"
            case "umbrella": return "\(count) cái ô"
            case "book": return "\(count) quyển sách"
            case "clock": return "\(count) đồng hồ"
            case "refrigerator": return "\(count) tủ lạnh"
            default: return nil
            }
        }

        // Tạo parts: ưu tiên người trước, sau đó vật khác theo nounsOrderEN
        var parts: [String] = []

        if let v = counts["person"], v > 0, let phrase = viPhrase(noun: "person", count: v) {
            parts.append(phrase)
        }

        for noun in nounsOrderEN where noun != "person" {
            if let v = counts[noun], v > 0, let phrase = viPhrase(noun: noun, count: v) {
                parts.append(phrase)
            }
        }

        let sentence = parts.isEmpty ? "" : ("Phía trước có " + parts.joined(separator: ", ") + ".")
        if !sentence.isEmpty {
            announce(text: sentence)
            lastSpokenSignature = stableSignature
            lastAnnounceAt = now
        }

        // Haptic nếu có người rất gần (bucket == 0)
        if let firstPerson = persons.first, firstPerson.bucket == 0 {
            triggerHaptic()
        }
    }

    
    // MARK: - Detection handling
//    private func handleDetections(request: VNRequest, error: Error?) {
//        guard let results = request.results as? [VNRecognizedObjectObservation], !results.isEmpty else { return }
//
//        let now = Date()
//        guard now.timeIntervalSince(appStartAt) > 1.5 else { return }
//
//        // Lọc theo confidence
//        let filtered = results.compactMap { obs -> VNRecognizedObjectObservation? in
//            guard let label = obs.labels.first else { return nil }
//            let cls = label.identifier.lowercased()
//
//            if cls.contains("person") {
//                // riêng person phải >= 0.65
//                guard label.confidence >= 0.65 else { return nil }
//            } else {
//                // còn lại dùng minConfidence chung (ví dụ 0.45)
//                guard label.confidence >= minConfidence else { return nil }
//            }
//            return obs
//        }
//        if filtered.isEmpty { return }
//
//        // Chuẩn hoá item + điểm gần
//        struct Item {
//            let cls: String
//            let noun: String
//            let bbox: CGRect
//            let proxScore: CGFloat   // càng cao càng gần
//            let bucket: Int          // 0 rất gần, 1 gần, 2 TB, 3 xa
//            var isPerson: Bool { cls.lowercased().contains("person") }
//        }
//
//        func proximityScore(_ b: CGRect) -> CGFloat {
//            let h = max(0, min(1, b.height))
//            let vertical = 1 - b.midY
//            return 0.7 * h + 0.3 * vertical
//        }
//        func distanceBucket(_ b: CGRect) -> Int {
//            let h = b.height
//            if h >= 0.45 { return 0 }
//            if h >= 0.28 { return 1 }
//            if h >= 0.15 { return 2 }
//            return 3
//        }
//
//        func viNoun(of cls: String) -> String {
//            let c = cls.lowercased()
//            switch true {
//            case c.contains("person"): return "người"
//            case c.contains("chair"): return "ghế"
//            case c.contains("table"): return "bàn"
//            case c.contains("dog"): return "chó"
//            case c.contains("cat"): return "mèo"
//            case c.contains("bicycle"): return "xe đạp"
//            case c.contains("motorcycle"): return "xe máy"
//            case c.contains("car"): return "xe hơi"
//            case c.contains("bed"): return "giường"
//            case c.contains("door"): return "cửa"
//            case c.contains("tv"): return "ti vi"
//            case c.contains("cell phone"): return "điện thoại di động"
//            case c.contains("laptop"): return "Máy tính xách tay"
//            case c.contains("umbrella"): return "cái ô"
//            case c.contains("book"): return "quyển sách"
//            case c.contains("clock"): return "đồng hồ"
//            case c.contains("refrigerator"): return "tủ lạnh"
//
//            default: return ""   // bỏ qua các nhãn khác
//            }
//        }
//
//        let items: [Item] = filtered.compactMap { obs in
//            let cls = obs.labels.first!.identifier
//            let n = viNoun(of: cls)
//            guard !n.isEmpty else { return nil }
//            return Item(
//                cls: cls,
//                noun: n,
//                bbox: obs.boundingBox,
//                proxScore: proximityScore(obs.boundingBox),
//                bucket: distanceBucket(obs.boundingBox)
//            )
//        }
//
//        // Ưu tiên người trước, sau đó vật; trong mỗi nhóm: gần → xa
//        let persons = items.filter { $0.isPerson }.sorted { $0.proxScore > $1.proxScore }
//        let others  = items.filter { !$0.isPerson }.sorted { $0.proxScore > $1.proxScore }
//        let ordered = Array((persons + others).prefix(20))
//        if ordered.isEmpty { return }
//
//        // Gom nhóm theo danh từ
//        var countsFrame: [String:Int] = [:]
//        ordered.forEach { countsFrame[$0.noun, default: 0] += 1 }
//
//        // Lưu lịch sử để lấy mode
//        countsHistory.append(countsFrame)
//        if countsHistory.count > countsHistoryLimit { countsHistory.removeFirst() }
//
//        // Thứ tự nhóm cần đọc
//        let nounsOrder = ["người","bàn","ghế","giường","cửa","chó","mèo","xe máy","xe đạp","xe hơi", "ti vi", "điện thoại di động", "Máy tính xách tay", "cái ô", "quyển sách", "đồng hồ","tủ lạnh"]
//
//        func stabilizedCounts(from history: [[String:Int]]) -> [String:Int] {
//            var out: [String:Int] = [:]
//            for noun in nounsOrder {
//                var freq: [Int:Int] = [:]
//                for h in history {
//                    let v = h[noun] ?? 0
//                    freq[v, default: 0] += 1
//                }
//                if let best = freq.max(by: { (a, b) -> Bool in
//                    if a.value == b.value { return a.key > b.key }
//                    return a.value < b.value
//                }) {
//                    out[noun] = best.key
//                } else {
//                    out[noun] = 0
//                }
//            }
//            return out
//        }
//
//        let counts = stabilizedCounts(from: countsHistory)
//
//        // Tạo chữ ký ổn định theo thứ tự cố định, bỏ nhóm = 0
//        let stableSignature: String = nounsOrder
//            .compactMap { n -> String? in
//                guard let v = counts[n], v > 0 else { return nil }
//                return "\(n):\(v)"
//            }
//            .joined(separator: ",")
//
////        let now = Date()
//        if stableSignature != candidateSignature {
//            candidateSignature = stableSignature
//            stableCounter = 1
//            return
//        } else {
//            stableCounter += 1
//        }
//
//        guard !stableSignature.isEmpty else { return }
//        guard stableSignature != lastSpokenSignature else { return }
//        guard stableCounter >= stabilityFramesRequired else { return }
//        guard now.timeIntervalSince(lastAnnounceAt) > minSpeakInterval else { return }
//
//        // Soạn câu
//        var parts: [String] = []
//        if let n = counts["người"], n > 0 { parts.append("\(n) người") }
//        for noun in nounsOrder where noun != "người" {
//            if let v = counts[noun], v > 0 {
//                switch noun {
//                case "bàn": parts.append("\(v) cái bàn")
//                case "ghế": parts.append("\(v) cái ghế")
//                case "giường": parts.append("\(v) cái giường")
//                case "cửa": parts.append("\(v) cái cửa")
//                case "chó": parts.append("\(v) con chó")
//                case "mèo": parts.append("\(v) con mèo")
//                case "xe máy": parts.append("\(v) xe gắn máy")
//                case "xe đạp": parts.append("\(v) xe đạp")
//                case "xe hơi": parts.append("\(v) xe ô tô")
//                case "ti vi": parts.append("\(v) ti vi")
//                case "điện thoại di động": parts.append("\(v) điện thoại di động")
//                case "Máy tính xách tay": parts.append("\(v) máy tính xách tay")
//                case "cái ô": parts.append("\(v) cái ô")
//                case "quyển sách": parts.append("\(v) quyển sách")
//                case "đồng hồ": parts.append("\(v) đồng hồ")
//                case "tủ lạnh": parts.append("\(v) tủ lạnh")
//                default: break
//                }
//            }
//        }
//
//        let sentence = parts.isEmpty ? "" : ("Phía trước có " + parts.joined(separator: ", ") + ".")
//        if !sentence.isEmpty {
//            announce(text: sentence)
//            lastSpokenSignature = stableSignature
//            lastAnnounceAt = now
//        }
//
//        if let firstPerson = persons.first, firstPerson.bucket == 0 {
//            triggerHaptic()
//        }
//    }

    // MARK: - Speech
    private func announce(text: String) {
        let u = AVSpeechUtterance(string: text)
        u.voice = AVSpeechSynthesisVoice(language: "vi-VN")
        u.rate = AVSpeechUtteranceDefaultSpeechRate
        speaker.speak(u)
    }

    // MARK: - Haptic
    private func triggerHaptic() {
        guard let engine = hapticEngine else { return }
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 1)
            ],
            relativeTime: 0
        )
        if let pattern = try? CHHapticPattern(events: [event], parameters: []) {
            if let player = try? engine.makePlayer(with: pattern) {
                try? player.start(atTime: 0)
            }
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension CameraObjectSpeaker: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Throttle theo thời gian thay vì frame
        let now = Date()
        guard now.timeIntervalSince(lastDetectionTime) >= detectionInterval else { return }
        lastDetectionTime = now

        guard let pixel = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let handler = VNImageRequestHandler(cvPixelBuffer: pixel, orientation: .up, options: [:])
        do {
            try handler.perform([detectionRequest])
        } catch {
            print("❌ Vision error: \(error)")
        }
    }
}
