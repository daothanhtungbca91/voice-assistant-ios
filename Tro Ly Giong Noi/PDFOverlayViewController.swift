//
//  PDFOverlayViewController.swift
//  Demo GPT API
//
//  Created by Tung Dao Thanh on 4/9/25.
//

import UIKit
import PDFKit

class PDFOverlayViewController: UIViewController {

    private let pdfFileName: String

    init(pdfFileName: String) {
        self.pdfFileName = pdfFileName
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overCurrentContext
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Nền mờ
        view.backgroundColor = UIColor.black.withAlphaComponent(0.7)

        // Container trắng cho PDF
        let container = UIView(frame: CGRect(x: 10,
                                             y: 80,
                                             width: view.bounds.width - 20,
                                             height: view.bounds.height - 160))
        container.backgroundColor = .white
        container.layer.cornerRadius = 12
        container.clipsToBounds = true
        container.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(container)

        // PDFView
        let pdfView = PDFView(frame: container.bounds)
        pdfView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        pdfView.autoScales = true
        container.addSubview(pdfView)

        if let fileURL = Bundle.main.url(forResource: pdfFileName, withExtension: "pdf") {
            pdfView.document = PDFDocument(url: fileURL)
        }

        // Nút Đóng (góc trên bên phải)
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("✕", for: .normal)
        closeButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 22)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        closeButton.layer.cornerRadius = 18
        closeButton.clipsToBounds = true
        closeButton.frame = CGRect(x: container.frame.maxX - 54,
                                   y: container.frame.minY - 18,
                                   width: 36, height: 36)
        closeButton.autoresizingMask = [.flexibleLeftMargin, .flexibleBottomMargin]
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        view.addSubview(closeButton)

        // Nút Download (góc trên bên trái)
        let downloadButton = UIButton(type: .system)
        let downloadIcon = UIImage(systemName: "arrow.down.circle") // icon SF Symbols
        downloadButton.setImage(downloadIcon, for: .normal)
        downloadButton.tintColor = .white
        downloadButton.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        downloadButton.layer.cornerRadius = 18
        downloadButton.clipsToBounds = true
        downloadButton.frame = CGRect(x: container.frame.minX + 18,
                                      y: container.frame.minY - 18,
                                      width: 36, height: 36)
        downloadButton.autoresizingMask = [.flexibleRightMargin, .flexibleBottomMargin]
        downloadButton.addTarget(self, action: #selector(downloadTapped), for: .touchUpInside)
        view.addSubview(downloadButton)
    }

    @objc private func closeTapped() {
        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
    }

    @objc private func downloadTapped() {
        guard let fileURL = Bundle.main.url(forResource: pdfFileName, withExtension: "pdf") else { return }
        
        // Mở menu chia sẻ/lưu file PDF
        let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        activityVC.popoverPresentationController?.sourceView = self.view
        present(activityVC, animated: true, completion: nil)
    }
}
