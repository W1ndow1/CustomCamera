//
//  CameraPreview.swift
//  CustomCamera
//
//  Created by window1 on 4/5/24.
//

import SwiftUI
import AVFoundation

struct CameraPreview: UIViewRepresentable {
    
    class VideoPreviewView: UIView {
        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }
        
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            return layer as! AVCaptureVideoPreviewLayer
        }
        
    }
    
    var session: AVCaptureSession
    
    
    func makeUIView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()
        view.backgroundColor = .black
        view.videoPreviewLayer.cornerRadius = 0
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.connection?.videoRotationAngle = 90
        return view
    }
    
    func updateUIView(_ uiView: VideoPreviewView, context: Context) {
    }
    
}

#Preview {
    CameraPreview(session: AVCaptureSession())
        .frame(height: 300)
}
