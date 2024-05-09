import Foundation

extension CameraService {
    enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFaild
    }
    
    enum CaptureMode: Int {
        case photo = 0
        case video = 1
    }
    
    enum PotraitEffectsMatteDeliveryMode {
        case on
        case off
    }
    
    enum LivePhotoMode {
        case on
        case off
    }
    
    enum CameraError: Error {
        case configurationFailed
    }
}
