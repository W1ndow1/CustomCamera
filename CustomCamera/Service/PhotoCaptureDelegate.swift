//
//  PhotoCaptureDelegate.swift
//  CustomCamera
//
//  Created by window1 on 5/9/24.
//

import Foundation
import Photos

class PhotoCaptureProcessorDelegate: NSObject {
    private(set) var requestPhotoSettings: AVCapturePhotoSettings
    private let willCapturePhotoAnimation: () -> Void
    private let livePhotoCaptureHandler: (Bool) -> Void
    
    private let completionHandler: (PhotoCaptureProcessorDelegate) -> Void
    private var photoData: Data?
    private var livePhotoCompanionMovieURL: URL?
    
    var location: CLLocation?
    var isSilentModeModeOn = false
    
    init(with requestPhotoSettings: AVCapturePhotoSettings, willCapturePhotoAnimation: @escaping () -> Void, livePhotoCaptureHandler: @escaping (Bool) -> Void, completionHandler: @escaping (PhotoCaptureProcessorDelegate) -> Void) {
        self.requestPhotoSettings = requestPhotoSettings
        self.willCapturePhotoAnimation = willCapturePhotoAnimation
        self.livePhotoCaptureHandler = livePhotoCaptureHandler
        self.completionHandler = completionHandler
    }
    
    //파일이 있는지 확인하고 지운다
    private func didFinish() {
        if let livePhotoCompanionMoviePath = livePhotoCompanionMovieURL?.path {
            if FileManager.default.fileExists(atPath: livePhotoCompanionMoviePath) {
                do {
                    try FileManager.default.removeItem(atPath: livePhotoCompanionMoviePath )
                } catch {
                    print("파일을 삭제 할 수 없습니다. \(livePhotoCompanionMoviePath)")
                }
            }
        }
        completionHandler(self)
    }
    
}

extension PhotoCaptureProcessorDelegate: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, willBeginCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        if resolvedSettings.livePhotoMovieDimensions.width > 0 && resolvedSettings.livePhotoMovieDimensions.height > 0 {
            livePhotoCaptureHandler(true)
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        willCapturePhotoAnimation()
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: (any Error)?) {
        if let error = error {
            print("Error Captureing Photo: \(error)")
            return
        }
        photoData = photo.fileDataRepresentation()
    }
    
    @available(iOS 17.0, *)
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCapturingDeferredPhotoProxy deferredPhotoProxy: AVCaptureDeferredPhotoProxy?, error: (any Error)?) {
        if let error = error {
            print("Error capturing deferred photo: \(error)")
            return
        }
        photoData = deferredPhotoProxy?.fileDataRepresentation()
    }
    
    // 라이브포토 레코딩이 끝났을때
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishRecordingLivePhotoMovieForEventualFileAt outputFileURL: URL, resolvedSettings: AVCaptureResolvedPhotoSettings) {
        livePhotoCaptureHandler(true)
    }
    
    // 라이브포토 프로세싱이 끝났을때
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingLivePhotoToMovieFileAt outputFileURL: URL, duration: CMTime, photoDisplayTime: CMTime, resolvedSettings: AVCaptureResolvedPhotoSettings, error: (any Error)?) {
        if error != nil {
            print("Error processing Live Photo companion movie: \(String(describing: error))")
            return
        }
        livePhotoCompanionMovieURL = outputFileURL
    }
    //캡쳐가 끝나면 저장하기
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: (any Error)?) {
        if let error = error {
            print("Error Capturing photo: \(error)")
            didFinish()
            return
        }
        
        guard photoData != nil else {
            print("No photo data resource")
            didFinish()
            return
        }
        
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                PHPhotoLibrary.shared().performChanges({
                    let options = PHAssetResourceCreationOptions()
                    let creationRequest = PHAssetCreationRequest.forAsset()
                    options.uniformTypeIdentifier = self.requestPhotoSettings.processedFileType.map {
                        $0.rawValue
                    }
                    var resourceType = PHAssetResourceType.photo
                    if resolvedSettings.deferredPhotoProxyDimensions.width > 0 && resolvedSettings.deferredPhotoProxyDimensions.height > 0 {
                        resourceType = PHAssetResourceType.photoProxy
                    }
                    creationRequest.addResource(with: resourceType, data: self.photoData!, options: options)
                    creationRequest.location = self.location
                    
                    if let livePhotoCompanionMovieURL = self.livePhotoCompanionMovieURL {
                        let livePhotoCompanionMovieFileOption = PHAssetResourceCreationOptions()
                        livePhotoCompanionMovieFileOption.shouldMoveFile = true
                        creationRequest.addResource(with: .pairedVideo, fileURL: livePhotoCompanionMovieURL, options: livePhotoCompanionMovieFileOption)
                    }
                }, completionHandler: { _, error in
                    if let error = error {
                        print("Photo Libraray에 저장하는 동안 오류가 발생했습니다. \(error)")
                    }
                    self.didFinish()
                }
                )
            } else {
                self.didFinish()
            }
        }
    }
}
