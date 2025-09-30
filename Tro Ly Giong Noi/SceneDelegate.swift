//
//  SceneDelegate.swift
//  Demo GPT API
//
//  Created by Tung Dao Thanh on 13/6/25.
//

import UIKit
import AVFoundation

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var pendingAction: (() -> Void)?
    private var wasBackground = false
    private var firstLaunch = true

    func scene(_ scene: UIScene,
               openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        handleDeepLink(url)
        print("---SceneDelegate \(url)")
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "blindchat" else { return }

        if url.host == "listen" {
            let action: () -> Void = {
                // đóng modal nếu có
                self.window?.rootViewController?.dismiss(animated: false, completion: {
                    // set lại root nếu cần
                    if let nav = self.window?.rootViewController as? UINavigationController {
                        nav.popToRootViewController(animated: false)
                    } else if !(self.window?.rootViewController is ViewController) {
                        let sb = UIStoryboard(name: "Main", bundle: nil)
                        let mainVC = sb.instantiateViewController(withIdentifier: "MAIN_VIEW") as! ViewController
                        let nav = UINavigationController(rootViewController: mainVC)
                        self.window?.rootViewController = nav
                        self.window?.makeKeyAndVisible()
                    }

                    // --- NEW: đảm bảo audio session đã được khởi tạo trước khi bắt đầu TTS/Recording
                    self.resetAudioSession()
                    // Reset synthesizer để clear previous state
                    VoiceManager.shared.resetSynthesizer()
                    VoiceManager.shared.stopAll()
                    VoiceManager.shared.isManuallyStopped = false

                    // nhỏ delay để AVAudioSession kịp active → giúp ổn định khi gọi TTS ngay lập tức
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        VoiceManager.shared.startListening()
                    }
                })
            }

            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               scene.activationState == .foregroundActive {
                action() // App đang active → chạy ngay
            } else {
                pendingAction = action // App chưa active → chạy sau
            }
        }

//        if url.host == "listen" {
//            let action: () -> Void = {
//                // 🔹 Nếu đang có modal (ví dụ CameraObjectSpeaker) → đóng hết
//                self.window?.rootViewController?.dismiss(animated: false, completion: {
//                    if let nav = self.window?.rootViewController as? UINavigationController {
//                        // Nếu root là Navigation → về Main
//                        nav.popToRootViewController(animated: false)
//                    } else if !(self.window?.rootViewController is ViewController) {
//                        // Nếu root không phải là Main thì ép set lại
//                        let sb = UIStoryboard(name: "Main", bundle: nil)
//                        let mainVC = sb.instantiateViewController(withIdentifier: "MAIN_VIEW") as! ViewController
//                        let nav = UINavigationController(rootViewController: mainVC)
//                        self.window?.rootViewController = nav
//                        self.window?.makeKeyAndVisible()
//                    }
//
//                    // 🔹 Reset state rồi bắt đầu nghe
//                    VoiceManager.shared.stopAll()
//                    VoiceManager.shared.startListening()
//                })
//            }
//
//            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
//               scene.activationState == .foregroundActive {
//                action() // 🔥 App đang active → chạy ngay
//            } else {
//                pendingAction = action // App chưa active → chạy sau
//            }
//        }
    }

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        print("scene")

        guard let _ = (scene as? UIWindowScene) else { return }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        print("---sceneDidDisconnect")

    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        print("---sceneDidBecomeActive")
        
        //ngăn màn hình khoá cả app
        UIApplication.shared.isIdleTimerDisabled = true
        
        if let action = pendingAction {
            print("action = pendingAction")
            action()
            pendingAction = nil
            firstLaunch = false
            wasBackground = false
            return
        }

        // 🔹 Luôn đưa về MainViewController khi app trở lại foreground
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let mainVC = sb.instantiateViewController(withIdentifier: "MAIN_VIEW") as! ViewController
        let nav = UINavigationController(rootViewController: mainVC)
        window?.rootViewController = nav
        window?.makeKeyAndVisible()

        // 🔹 Reset audio session và khởi động trợ lý
        
        resetAudioSession()
        VoiceManager.shared.resetSynthesizer()
        VoiceManager.shared.stopAll()
        VoiceManager.shared.isManuallyStopped = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            VoiceManager.shared.startListening()
        }

        // Reset flags
        firstLaunch = false
        wasBackground = false
    }


//    func sceneDidBecomeActive(_ scene: UIScene) {
//        print("---sceneDidBecomeActive")
//
//        if let action = pendingAction {
//            print("action = pendingAction")
//            action()
//            pendingAction = nil
//            firstLaunch = false
//            wasBackground = false
//            return
//        }
//
//        // 🔹 Chỉ reset audio session khi chuẩn bị startListening
//        func resetAudioSession() {
//            let audioSession = AVAudioSession.sharedInstance()
//            do {
//                try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
//                try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
//            } catch {
//                print("❌ Lỗi reset audio session: \(error)")
//            }
//        }
//
//        if firstLaunch {
//            firstLaunch = false
//            resetAudioSession()
//            VoiceManager.shared.stopAll()
//            VoiceManager.shared.startListening()
//        } else if wasBackground {
//            wasBackground = false
//            resetAudioSession()
//            VoiceManager.shared.stopAll()
//            VoiceManager.shared.startListening()
//        } else {
//            print("⚠️ sceneDidBecomeActive nhưng không phải firstLaunch hay background → bỏ qua")
//        }
//    }

    func sceneWillResignActive(_ scene: UIScene) {
        print("---sceneWillResignActive")

    }

    func sceneWillEnterForeground(_ scene: UIScene) {
//        VoiceManager.shared.stopAll()
//        VoiceManager.shared.startListening()
        print("---sceneWillEnterForeground")
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Reset state khi app đi background
        print("---sceneDidEnterBackground")
        
        UIApplication.shared.isIdleTimerDisabled = false

        wasBackground = true
        VoiceManager.shared.stopAll()
        if let vc = window?.rootViewController as? ViewController {
            vc.stopAllTime()
        }

    }
    
    private func resetAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            print("✅ audio session reset ok")
        } catch {
            print("❌ Lỗi reset audio session: \(error)")
        }
    }

}
