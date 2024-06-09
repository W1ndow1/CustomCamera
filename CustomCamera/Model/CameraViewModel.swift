import Foundation
import AVFoundation
import SwiftUI
import Combine
import PhotosUI

class CameraViewModel: ObservableObject {
    
    private let camera: Camera
    private let session: AVCaptureSession
    private let sessionQueue = DispatchQueue(label: "session queue")
    private var subscriptions = Set<AnyCancellable>()
    private var isCameraBusy = false
    let cameraPreview: CameraPreview
    let hapticImpact = UIImpactFeedbackGenerator()
    
    var currentZoomValue: CGFloat = 1.0
    var lastZoomValue: CGFloat = 1.0
    
    @Published var waterMarkImage: UIImage?
    @Published var recentImage: UIImage?
    @Published var isFlashedOn = false
    @Published var isSilentModeOn = false
    @Published var isLivePhotoOn = false
    @Published var shutterEffect = false
    @Published var imageSelection: PhotosPickerItem? = nil
    @Published var isWaterMarkOn = false
    @Published var waterMarkText = ""
    
    func configure() {
        camera.requestAndCheckPermission()
    }
    
    func startSession() {
        camera.startCamera()
    }
    
    
    func stopSession() {
        camera.stopCamera()
    }
    
    func switchToLens(position :AVCaptureDevice.DeviceType) {
        camera.switchToLens(position: position)
        
    }
    
    func switchWaterMark() {
        isWaterMarkOn.toggle()
    }
    
    
    func switchFlash() {
        isFlashedOn.toggle()
        camera.flashMode = isFlashedOn ? .on : .off
    }
    
    func switchSilent() {
        isSilentModeOn.toggle()
        camera.isSilentModeOn = self.isSilentModeOn
    }
    
    func switchLivePhoto() {
        isLivePhotoOn.toggle()
        camera.livePhotoMode = self.isLivePhotoOn ? .on : .off
        camera.toggleLivePhotoMode()
    }
    
    func capturePhoto() {
        camera.capturePhoto()
        if isCameraBusy == false {
            hapticImpact.impactOccurred()
            withAnimation(.easeInOut(duration: 0.1)) {
                shutterEffect = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    self.shutterEffect = false
                }
            }
            
        } else {
            print("Camera is Busy")
        }
    }
    
    func flipCamera() {
        camera.flipCamera()
    }
    
    func zoom(factor: CGFloat) {
        let delta = factor / lastZoomValue
        lastZoomValue = factor
        
        let newScale = min(max(currentZoomValue * delta, 1), 5)
        camera.zoom(newScale)
        currentZoomValue = newScale
    }
    
    func zoomInitialize() {
        lastZoomValue = 1.0
    }
    
    func sendWaterMarkImage(_ mark: UIImage) {
        camera.waterMarkReceive(image: mark)
    }
    
    func focusAndExposeTap(_ devicePoint: CGPoint) {
        camera.focus(with: .autoFocus, exposureMode: .autoExpose, at: devicePoint, monitorSubjectAreaChange: true)
    }
    
    init() {
        self.camera = Camera()
        session = camera.session
        cameraPreview = CameraPreview(session: session)
        
        camera.$recentImage.sink { [weak self] capturePhoto in
            guard let pic = capturePhoto else { return }
            self?.recentImage = pic
        }
        .store(in: &self.subscriptions)
        
        camera.$isCameraBusy.sink { [weak self] result in
            self?.isCameraBusy = result
        }
        .store(in: &self.subscriptions)
        
        $waterMarkImage
            .sink { [weak self] updateData in
                self?.sendWaterMarkImage(updateData ?? UIImage())
            }
            .store(in: &subscriptions)
    }
}
