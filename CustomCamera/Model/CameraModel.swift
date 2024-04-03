//
//  CameraModel.swift
//  CustomCamera
//
//  Created by window1 on 3/29/24.
//

import Foundation
import SwiftUI
import AVKit

class CameraModel: ObservableObject {
    
    @Published var captureSession = AVCaptureSession()
    @Published var ouput = AVCapturePhotoOutput()
    @Published var setting = AVCapturePhotoSettings()
    @Published var previewLayer = AVCaptureVideoPreviewLayer()
    
    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] status in
                guard status else { return }
                DispatchQueue.main.async {
                    self?.setUpCamera()
                }
            }
        case .restricted:
            break
        case .authorized:
            setUpCamera()
        case .denied:
            break
        @unknown default:
            break
        }
    }
    
    func setUpCamera() {
        captureSession.beginConfiguration()
        do {
            
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
            let input = try AVCaptureDeviceInput(device: device!)
            
            guard captureSession.canAddInput(input) else { return }
            captureSession.addInput(input)
            guard captureSession.canAddOutput(ouput) else { return }
            captureSession.addOutput(ouput)
            
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.session = captureSession
            
            captureSession.startRunning()
            self.captureSession = captureSession
            
        } catch {
            print(error.localizedDescription)
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
    }
    
}

