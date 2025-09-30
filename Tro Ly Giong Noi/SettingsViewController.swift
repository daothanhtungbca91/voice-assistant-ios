//
//  SettingsViewController.swift
//  Good Morning and Good Night
//
//  Created by Tung Dao Thanh on 19/5/25.
//

import UIKit
import AVFoundation
import PDFKit

class SettingsViewController: UIViewController {
            
    @IBOutlet weak var img_back: UIImageView!
    
    @IBOutlet weak var view_huong_dan: UIView!
    @IBOutlet weak var img_huong_dan_doc: UIImageView!
    @IBOutlet weak var img_huong_dan_speak: UIImageView!
    
    @IBOutlet weak var view_huong_dan_su_dung: UIView!
    
    @IBOutlet weak var view_toc_do_doc: UIView!
    @IBOutlet weak var img_toc_do_doc_giam: UIImageView!
    @IBOutlet weak var img_toc_do_doc_tang: UIImageView!
    @IBOutlet weak var lable_toc_do_doc: UILabel!
    
    @IBOutlet weak var view_giong_doc: UIView!
    @IBOutlet weak var lable_nguoi_doc: UILabel!
    @IBOutlet weak var view_time_out: UIView!
    @IBOutlet weak var img_time_out_giam: UIImageView!
    @IBOutlet weak var img_time_out_tang: UIImageView!
    @IBOutlet weak var lable_time_out: UILabel!
    @IBOutlet weak var view_xin_chao: UIView!
    
    @IBOutlet weak var view_camera_preview: UIView!
    @IBOutlet weak var switch_camera_preview: UISwitch!
    
    var is_speaking: Bool = false
    
    var current_voice_index: Int = 0
    var current_time_out_index: Int = 2
    
    @IBAction func camera_preview(_ sender: UISwitch) {
        if (sender.isOn) {
            print("camera_preview on")
        }else{
            print("camera_preview off")
        }
        UserDefaults.standard.set(sender.isOn, forKey: StringResources.key_camera_preview)
    }
    
//    @IBAction func switch_action(_ sender: UISwitch) {
//        if (sender.isOn) {
//            print("switch_speak on")
//
//        }else{
//            print("switch_speak off")
//        }
//        UserDefaults.standard.set(sender.isOn, forKey: StringResources.key_speak_time)
//
//    }
    
    var giong_doc_index: Int = 0
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view_huong_dan.layer.cornerRadius = 15
        view_huong_dan_su_dung.layer.cornerRadius = 15
        view_toc_do_doc.layer.cornerRadius = 15
        view_giong_doc.layer.cornerRadius = 15
        view_time_out.layer.cornerRadius = 15
        view_xin_chao.layer.cornerRadius = 15
        view_camera_preview.layer.cornerRadius = 15
        
        switch_camera_preview.setOn(ViewController.usd_getBool(for: StringResources.key_camera_preview, default: true), animated: false)

        lable_toc_do_doc.text = String(format: "%.1f", SettingsViewController.usd_getFloat(for: StringResources.key_speechRate, default: StringResources.default_speak_rate))
        
        lable_time_out.text = String(SettingsViewController.usd_getInt(for: StringResources.key_time_out, default: StringResources.default_time_out_count))
                
        let voices = AVSpeechSynthesisVoice.speechVoices()
        let vietnameseVoices = voices.filter { $0.language.hasPrefix("vi") }
        current_voice_index = SettingsViewController.usd_getInt(for: StringResources.key_speechVoice, default: 0)
        lable_nguoi_doc.text = vietnameseVoices[current_voice_index].name
        
        let tapChangeGiongDoc = UITapGestureRecognizer(target: self, action: #selector(viewChangeGiongDocTapped(tapChangeGiongDoc:)))
        view_giong_doc.isUserInteractionEnabled = true
        view_giong_doc.addGestureRecognizer(tapChangeGiongDoc)
                
        let tapBack = UITapGestureRecognizer(target: self, action: #selector(imageBackTapped(tapBack:)))
        img_back.isUserInteractionEnabled = true
        img_back.addGestureRecognizer(tapBack)
        
        let tapHuongDanSpeak = UITapGestureRecognizer(target: self, action: #selector(imageDocTapped(tapHuongDanSpeak:)))
        img_huong_dan_speak.isUserInteractionEnabled = true
        img_huong_dan_speak.addGestureRecognizer(tapHuongDanSpeak)

        let tapHuongDanText = UITapGestureRecognizer(target: self, action: #selector(imageTextTapped(tapHuongDanText:)))
        img_huong_dan_doc.isUserInteractionEnabled = true
        img_huong_dan_doc.addGestureRecognizer(tapHuongDanText)
        
        let tapGiamTocDo = UITapGestureRecognizer(target: self, action: #selector(imageGiamTocDoTapped(tapGiamTocDo:)))
        img_toc_do_doc_giam.isUserInteractionEnabled = true
        img_toc_do_doc_giam.addGestureRecognizer(tapGiamTocDo)

        let tapTangTocDo = UITapGestureRecognizer(target: self, action: #selector(imageTangTocDoTapped(tapTangTocDo:)))
        img_toc_do_doc_tang.isUserInteractionEnabled = true
        img_toc_do_doc_tang.addGestureRecognizer(tapTangTocDo)
        
        let tapGiamTimeOut = UITapGestureRecognizer(target: self, action: #selector(imageGiamTimeOutTapped(tapGiamTimeOut:)))
        img_time_out_giam.isUserInteractionEnabled = true
        img_time_out_giam.addGestureRecognizer(tapGiamTimeOut)

        
        let tapTangTimeOut = UITapGestureRecognizer(target: self, action: #selector(imageTangTimeOutTapped(tapTangTimeOut:)))
        img_time_out_tang.isUserInteractionEnabled = true
        img_time_out_tang.addGestureRecognizer(tapTangTimeOut)

        let tapPhoneNumber = UITapGestureRecognizer(target: self, action: #selector(viewPhoneNumberTapped(tapPhoneNumber:)))
        view_xin_chao.isUserInteractionEnabled = true
        view_xin_chao.addGestureRecognizer(tapPhoneNumber)

        set_background()
    }
    
    @objc func viewPhoneNumberTapped(tapPhoneNumber: UITapGestureRecognizer)
    {
//        presentTextInputAlert(for: lable_xin_chao)
        if let url = URL(string: "mailto:\(StringResources.support_email)") {
            UIApplication.shared.open(url)
        }

    }

    
    @objc func imageTangTimeOutTapped(tapTangTimeOut: UITapGestureRecognizer)
    {

        if (current_time_out_index < 10){
            current_time_out_index = current_time_out_index + 1
            lable_time_out.text = String(current_time_out_index)
            UserDefaults.standard.set(current_time_out_index, forKey: StringResources.key_time_out)
            print("current_time_out_index is \(current_time_out_index)")
        }else {
            showToast(message: "Time out tối đa", width: 150)
        }
    }
    
    @objc func imageGiamTimeOutTapped(tapGiamTimeOut: UITapGestureRecognizer)
    {

        if (current_time_out_index >= 3){
            current_time_out_index = current_time_out_index - 1
            lable_time_out.text = String(current_time_out_index)
            UserDefaults.standard.set(current_time_out_index, forKey: StringResources.key_time_out)
            print("current_time_out_index is \(current_time_out_index)")
        }else {
            showToast(message: "Time out tối thiểu", width: 150)
        }
    }

    @objc func imageTangTocDoTapped(tapTangTocDo: UITapGestureRecognizer)
    {
        //tăng tốc độ đọc

        var speed = SettingsViewController.usd_getFloat(for: StringResources.key_speechRate, default: StringResources.default_speak_rate)
        if (AVSpeechUtteranceMaximumSpeechRate - speed > 0.1){
            speed = speed + 0.1
            lable_toc_do_doc.text = String(format: "%.1f", speed)
            UserDefaults.standard.set(speed, forKey: StringResources.key_speechRate)
            print("Speed is \(speed)")
        }else {
            showToast(message: "Tốc độ đọc tối đa", width: 150)
        }
    }
    
    @objc func imageGiamTocDoTapped(tapGiamTocDo: UITapGestureRecognizer)
    {
        var speed = SettingsViewController.usd_getFloat(for: StringResources.key_speechRate, default: StringResources.default_speak_rate)
        if (speed - AVSpeechUtteranceMinimumSpeechRate > 0.11){
            speed = speed - 0.1
            lable_toc_do_doc.text = String(format: "%.1f", speed)
            UserDefaults.standard.set(speed, forKey: StringResources.key_speechRate)
            print("Speed is \(speed)")

        }else {
            showToast(message: "Tốc độ đọc tối thiểu", width: 150)
        }
    }
    
    @objc func imageTextTapped(tapHuongDanText: UITapGestureRecognizer)
    {
        //mở hướng dẫn ở đây
        let pdfVC = PDFOverlayViewController(pdfFileName: "huongdansudung")
        addChild(pdfVC)
        view.addSubview(pdfVC.view)
        pdfVC.didMove(toParent: self)

    }
    
    @objc func imageDocTapped(tapHuongDanSpeak: UITapGestureRecognizer)
    {
        is_speaking = !is_speaking
        if (is_speaking){
            VoiceManager.shared.speak(StringResources.huong_dan_su_dung)
            img_huong_dan_speak.image = UIImage(systemName: "speaker.slash.circle")
        }else{
            VoiceManager.shared.stopSpeaking()
            img_huong_dan_speak.image = UIImage(systemName: "speaker.wave.2.circle")
        }
    }
    
    @objc func imageBackTapped(tapBack: UITapGestureRecognizer)
    {
        
        self.navigationController?.popViewController(animated: true)
    }

    @objc func viewChangeGiongDocTapped(tapChangeGiongDoc: UITapGestureRecognizer)
    {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        
        // Lọc ra chỉ giọng tiếng Việt
        let vietnameseVoices = voices.filter { $0.language.hasPrefix("vi") }
        
        if vietnameseVoices.count == 1 {
            showToast(message: "Điện thoại chỉ có 1 giọng đọc", width: 250)
        }else{
            
            if current_voice_index == vietnameseVoices.count-1 {
                current_voice_index = 0
            }else{
                current_voice_index = current_voice_index + 1
            }
            let voice = vietnameseVoices[current_voice_index]
            print("Name: \(voice.name), Identifier: \(voice.identifier), Language: \(voice.language)")
            lable_nguoi_doc.text = voice.name
            UserDefaults.standard.set(current_voice_index, forKey: StringResources.key_speechVoice)
        }
        
    }
    
//    func presentTextInputAlert(for textView: UILabel, title: String = "Số điện thoại", message: String = "Nhập số điện thoại mặc định để gọi") {
//        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
//
//        // Thêm text field
//        alert.addTextField { textField in
//            textField.placeholder = "0987654321"
//        }
//
//        // Nút OK
//        let confirmAction = UIAlertAction(title: "Lưu", style: .default) { _ in
//            if let userInput = alert.textFields?.first?.text, !userInput.isEmpty {
//                textView.text = userInput
//                UserDefaults.standard.set(userInput, forKey: StringResources.key_phone_number)
//            }
//        }
//
//        // Nút Cancel
//        let cancelAction = UIAlertAction(title: "Huỷ", style: .cancel, handler: nil)
//
//        alert.addAction(confirmAction)
//        alert.addAction(cancelAction)
//
//        // Hiển thị alert
//        if let vc = UIApplication.shared.keyWindow?.rootViewController {
//            vc.present(alert, animated: true, completion: nil)
//        }
//    }
        
    func set_background(){
                
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    

    func showToast(message : String, width: CGFloat) {

        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - width/2, y: self.view.frame.size.height-130, width: width, height: 35))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.font = .systemFont(ofSize: 15.0)
        toastLabel.textAlignment = .center;
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10;
        toastLabel.clipsToBounds  =  true
        self.view.addSubview(toastLabel)
        UIView.animate(withDuration: 4.0, delay: 0.1, options: .curveEaseOut, animations: {
             toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        VoiceManager.shared.stopSpeaking()
        
    }
    
    public static func usd_getInt(for key: String, default defaultValue: Int) -> Int {
        let defaults = UserDefaults.standard
        return defaults.object(forKey: key) == nil ? defaultValue : defaults.integer(forKey: key)
    }
    
    public static func usd_getBool(for key: String, default defaultValue: Bool) -> Bool {
        let defaults = UserDefaults.standard
        return defaults.object(forKey: key) == nil ? defaultValue : defaults.bool(forKey: key)
    }
    
    public static func usd_getFloat(for key: String, default defaultValue: Float) -> Float {
        let defaults = UserDefaults.standard
        return defaults.object(forKey: key) == nil ? defaultValue : defaults.float(forKey: key)
    }
    
    public static func usd_getString(for key: String, default defaultValue: String) -> String {
        let defaults = UserDefaults.standard
        return defaults.object(forKey: key) == nil ? defaultValue : defaults.string(forKey: key)!
    }

    
}

