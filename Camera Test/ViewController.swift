//
//  ViewController.swift
//  Camera Test
//
//  Created by Ryo on 2020/12/28.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    /// カメラのプレビューを表示するビュー
    @IBOutlet weak var previewView: UIView!
    /// 撮影した画像を表示するビュー
    @IBOutlet weak var takenPhotoImageView: UIImageView!
    /// 撮影ボタン
    @IBOutlet weak var takePhotoButton: UIButton!
    /// 読み込み表示
    @IBOutlet weak var indicatorView: UIView!

    var captureSession: AVCaptureSession!
    var photoOutput: AVCapturePhotoOutput!
    var previewLayer: AVCaptureVideoPreviewLayer!

    override func viewDidLoad() {
        super.viewDidLoad()

        // 最初は読み込み表示を非表示にする
        indicatorView.isHidden = true

        setupCamera()
    }

    /// カメラをセットアップする
    private func setupCamera() {
        captureSession = AVCaptureSession()
        photoOutput = AVCapturePhotoOutput()

        // 解像度の設定
        captureSession.sessionPreset = .photo

        guard let device = AVCaptureDevice.default(for: .video) else {
            fatalError("Could not get AVCaptureDevice instance.")
        }

        do {
            let input = try AVCaptureDeviceInput(device: device)

            guard captureSession.canAddInput(input) && captureSession.canAddOutput(photoOutput) else {
                fatalError("Could not add either input or output to the session.")
            }

            captureSession.addInput(input)
            captureSession.addOutput(photoOutput)
            captureSession.startRunning()

            // プレビューの設定
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            // 余白ができないようにビューに表示する
            previewLayer.videoGravity = .resizeAspectFill
            // 縦向き
            previewLayer.connection?.videoOrientation = .portrait

            // プレビュービューにプレビューを設定
            previewView.layer.addSublayer(previewLayer)
        } catch {
            fatalError("An error occurred while instantiating AVCaptureDeviceInput: \(error)")
        }
    }

    override func viewDidLayoutSubviews() {
        // Note: プレビューの位置調整はframeの値を用いるのでAutoLayout完了後に行う
        // プレビューをビューの中央に配置
        previewLayer.position = CGPoint(x: previewView.frame.width / 2, y: previewView.frame.height / 2)
        // プレビューのboundsをビューと同じ大きさに設定
        previewLayer.bounds = previewView.frame
    }

    /// 撮影ボタンが押されたときの処理
    /// - Parameter sender: 押されたボタン
    @IBAction func takePhotoButtonWasTapped(_ sender: UIButton) {
        indicatorView.isHidden = false

        // 数秒かかるのでmainスレッドでは行わない
        DispatchQueue.global(qos: .userInitiated)
            .async {
                // カメラの設定
                let settingsForMonitoring = AVCapturePhotoSettings()
                settingsForMonitoring.flashMode = .auto
                settingsForMonitoring.isHighResolutionPhotoEnabled = false

                // 撮影
                self.photoOutput.capturePhoto(with: settingsForMonitoring, delegate: self)
            }
    }
}

extension ViewController : AVCapturePhotoCaptureDelegate {

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil else {
            let error = error!
            fatalError("An error occurred after capturing process: \(error)")
        }

        if let imageData = photo.fileDataRepresentation(),
           let image = UIImage(data: imageData),
           let croppedImage = image.cropping(to: takenPhotoImageView.bounds.size) {
            // 撮影した画像をプレビュービューのサイズに切り取れたら表示する
            takenPhotoImageView.image = croppedImage
        }

        indicatorView.isHidden = true
    }
}
