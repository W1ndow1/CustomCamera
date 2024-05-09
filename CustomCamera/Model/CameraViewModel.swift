import Foundation
import AVFoundation
import SwiftUI
import Combine
import PhotosUI

class CameraViewModel: ObservableObject {
    
    private let camera: Camera
    private let session: AVCaptureSession
    private var subscriptions = Set<AnyCancellable>()
    private var isCameraBusy = false
    let cameraPreview: AnyView
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
    @Published var isWaterMarkOn = true
    @Published var waterMarkText = ""
    
    func configure() {
        camera.requestAndCheckPermission()
    }
    
    func switchToLens(position :AVCaptureDevice.DeviceType) {
        print("\(position.rawValue)로 변경합니다.")
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
            camera.capturePhoto()
            
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
    
    func sendWaterMarkImage(mark: UIImage) {
        camera.waterMarkReceive(image: mark)
    }
    
    init() {
        self.camera = Camera()
        session = camera.session
        cameraPreview = AnyView(CameraPreview(session: session))
        
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
                self?.sendWaterMarkImage(mark: updateData ?? UIImage())
            }
            .store(in: &subscriptions)
    }
}
