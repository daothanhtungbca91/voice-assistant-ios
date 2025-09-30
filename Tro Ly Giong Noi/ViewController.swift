//
//  ViewController.swift
//  Demo GPT API
//
//  Created by Tung Dao Thanh on 13/6/25.
//

import UIKit
import AVFAudio
import Speech
import SDWebImage

class ViewController: UIViewController, VoiceManagerDelegate, CameraObjectSpeakerDelegate {
    
    func didRequestOpenCamera() {
        let cameraVC = CameraObjectSpeaker()
        cameraVC.delegate = self
        present(cameraVC, animated: true)
    }

    func cameraObjectSpeakerDidFinish(_ controller: CameraObjectSpeaker) {
        controller.dismiss(animated: true) {
            // Sau khi camera đóng thì bật lại voice
            VoiceManager.shared.startListening()
        }
    }
    

    @IBOutlet weak var tv_time: UILabel!
    
    @IBOutlet weak var img_start_stop_speak: UIImageView!
    
    @IBOutlet weak var img_setting: UIImageView!
        
    private let synthesizer = AVSpeechSynthesizer()
    
    private var timer: Timer?
    
    var hasTriggeredHaptic = false
    
    private var isRunning = false

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self.view)
        
        if img_start_stop_speak.frame.contains(location) {
            if !hasTriggeredHaptic {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                hasTriggeredHaptic = true
            }
        } else {
            hasTriggeredHaptic = false
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        hasTriggeredHaptic = false
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        hasTriggeredHaptic = false
    }
            
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("---viewDidLoad")
        
        startClock()
        // Do any additional setup after loading the view.
        
        requestMicPermission()
        requestSpeechPermission()
        requestCameraPermission { granted in
            if granted {
                print("Đã cấp quyền camera")
            } else {
                print("Không cấp quyền camera")

            }
        }
                
        img_start_stop_speak.contentMode = .scaleAspectFill
        img_start_stop_speak.clipsToBounds = true
        img_start_stop_speak.layer.cornerRadius = img_start_stop_speak.layer.frame.width / 2
        
        if let path = Bundle.main.path(forResource: "mic", ofType: "gif") {
            let url = URL(fileURLWithPath: path)
            img_start_stop_speak.sd_setImage(with: url)
        }
        
        img_start_stop_speak.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        img_start_stop_speak.addGestureRecognizer(tap)

        syncUIWithVoiceManager()
        
        VoiceManager.shared.delegate = self
        
        // Lắng nghe khi VoiceManager thay đổi
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onMicStateChanged(_:)),
            name: .micStateChanged,
            object: nil
        )

        let tapSettings = UITapGestureRecognizer(target: self, action: #selector(viewSettingsTapped(tapSettings:)))
        img_setting.isUserInteractionEnabled = true
        img_setting.addGestureRecognizer(tapSettings)

    }
    
    @objc func viewSettingsTapped(tapSettings: UITapGestureRecognizer)
    {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        
        let setting_controller = sb.instantiateViewController(withIdentifier: "SETTING_VIEW") as! SettingsViewController
                
        self.navigationController!.pushViewController(setting_controller, animated: true)

    }
    
    @objc func onMicStateChanged(_ notification: Notification) {
        if let state = notification.userInfo?["isListening"] as? Bool {
            setMicState(state)
        }
    }
    
    func syncUIWithVoiceManager() {
        let running = VoiceManager.shared.isListening
        setMicState(running)   // dùng lại hàm setMicState mà mình gửi hôm trước
    }
    
    @objc private func handleTap() {
        if isRunning {
            VoiceManager.shared.stopAll(announceStop: true)
            setMicState(false)
        } else {
            VoiceManager.shared.startListening()
            setMicState(true)
        }
    }

    func setMicState(_ isRunning: Bool) {
        if isRunning {
            // 🟢 Chế độ đang nghe → hiển thị GIF động
            if let path = Bundle.main.path(forResource: "mic", ofType: "gif") {
                let url = URL(fileURLWithPath: path)
                img_start_stop_speak.sd_setImage(with: url)
            }
        } else {
            // 🔴 Chế độ stop → hiển thị frame tĩnh
            img_start_stop_speak.stopAnimating()
            if let path = Bundle.main.path(forResource: "mic", ofType: "gif"),
               let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
               let animatedImage = SDAnimatedImage(data: data),
               let firstFrame = animatedImage.animatedImageFrame(at: 0) {
               img_start_stop_speak.image = firstFrame
            }
        }

        // ✅ Đồng bộ lại biến trạng thái trong VC
        self.isRunning = isRunning
    }
    
    private var isSpeakingTime = false
    private var timeSynthesizer = AVSpeechSynthesizer()

    private func startClock() {
        updateTimeLabel() // Gọi lần đầu ngay lập tức
        timer = Timer.scheduledTimer(timeInterval: 1.0,
                                         target: self,
                                         selector: #selector(updateTimeLabel),
                                         userInfo: nil,
                                         repeats: true)
    }
    
    @objc func updateTimeLabel() {
        let now = Date()
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss"
        let timeString = timeFormatter.string(from: now)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        let dateString = dateFormatter.string(from: now)
        
        // Attributed text cho 2 dòng
        let fullText = NSMutableAttributedString(
            string: "\(timeString)\n",
            attributes: [
                .font: UIFont.systemFont(ofSize: 60, weight: .bold),
                .foregroundColor: UIColor.white
            ]
        )
        
        let dateText = NSAttributedString(
            string: dateString,
            attributes: [
                .font: UIFont.systemFont(ofSize: 25, weight: .regular),
                .foregroundColor: UIColor.white
            ]
        )
        
        fullText.append(dateText)
        
        tv_time.attributedText = fullText
    }

    deinit {
        timer?.invalidate()
    }
        
    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: "Quyền truy cập", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true)
    }
    
    private func requestSpeechPermission() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    print("✅ Đã cấp quyền nhận dạng giọng nói")
                case .denied:
                    self.showAlert("Bạn đã từ chối quyền nhận dạng giọng nói")
                case .restricted, .notDetermined:
                    self.showAlert("Không thể sử dụng nhận dạng giọng nói")
                @unknown default:
                    break
                }
            }
        }
    }

    /// Quyền micro (AVAudioSession)
    private func requestMicPermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                if granted {
                    print("✅ Đã cấp quyền micro")
                } else {
                    self.showAlert("Bạn đã từ chối quyền micro")
                }
            }
        }
    }
    
    private func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true) // đã có quyền
            print("Đã cấp quyền camera")
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        default:
            completion(false) // bị từ chối hoặc giới hạn
        }
    }
    
    func stopAllTime() {
        print("stopAllTime called")

        // Ngắt flag
        isSpeakingTime = false
        isRunning = false
        
        // Dừng đọc giờ ngay lập tức
        if timeSynthesizer.isSpeaking {
            timeSynthesizer.stopSpeaking(at: .immediate)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        print("---viewWillDisappear")
        VoiceManager.shared.stopAll()
        stopAllTime()
    }
    
    public static func usd_getBool(for key: String, default defaultValue: Bool) -> Bool {
        let defaults = UserDefaults.standard
        return defaults.object(forKey: key) == nil ? defaultValue : defaults.bool(forKey: key)
    }
    
    public static func usd_getInt(for key: String, default defaultValue: Int) -> Int {
        let defaults = UserDefaults.standard
        return defaults.object(forKey: key) == nil ? defaultValue : defaults.integer(forKey: key)
    }
    
}

extension ViewController: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        if synthesizer == timeSynthesizer {
            // ✅ Nếu đã bị stopAllTime thì không làm gì cả
            guard isSpeakingTime else { return }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.isSpeakingTime = false
                VoiceManager.shared.isManuallyStopped = false
                VoiceManager.shared.startListening()
            }
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        if synthesizer == timeSynthesizer {
            // Nếu bị hủy giữa chừng thì reset flag, không bật lại nghe
            self.isSpeakingTime = false
            VoiceManager.shared.isManuallyStopped = false
        }
    }
    
}
