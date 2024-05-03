
import Foundation
import SwiftUI
import AVKit
import Combine

class CameraModel: ObservableObject {
    
    private let service = CameraService()
    
    @Published var photo: Photo!
    @Published var showAlertError = false
    @Published var isFlashOn = false
    @Published var willCapturePhoto = false
    @Published var isSilentModeOn = false
    
    var alertError: AlertError!
    
    var session: AVCaptureSession
    
    private var subscriptions = Set<AnyCancellable>()
    
    init() {
        self.session = service.session
        
        service.$photo.sink { [weak self] photo in
            guard let pic = photo else { return }
            self?.photo = pic
        }
        .store(in: &self.subscriptions)
        
        service.$shouldShowAlertView.sink { [weak self] (val) in
            self?.alertError = self?.service.alertError
            self?.showAlertError = val
        }
        .store(in: &self.subscriptions)
        
        service.$flashMode.sink { [weak self] (mode) in
            self?.isFlashOn = mode == .on
        }
        .store(in: &self.subscriptions)
        
        service.$willCapturePhoto.sink { [weak self] (val) in
            self?.willCapturePhoto = val
        }
        .store(in: &self.subscriptions)
    }
    
    func configure() {
        service.checkPermission()
        service.configure()
    }
    
    func capturePhoto() {
        print("Captured Photo")
        service.capturePhoto()
    }
    
    func flipCamera() {
        print("Filp Camera")
        service.changeCamera()
    }
    
    func zoom(with factor: CGFloat) {
        service.setZoom(zoom: factor)
    }
    
    func switchFlash() {
        service.flashMode = (service.flashMode == .on ? .off : .on)
    }
    func switchShutterSound() {
        isSilentModeOn.toggle()
    }
}

