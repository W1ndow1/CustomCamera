import Foundation
import SwiftUI
import UIKit
import AVFoundation


class Camera: NSObject, ObservableObject {
    
    var session = AVCaptureSession()
    var videoDeviceInput: AVCaptureDeviceInput!
    var photoOutput = AVCapturePhotoOutput()
    var photoData: Data?
    var waterMark: UIImage?
    var flashMode: AVCaptureDevice.FlashMode = .off
    var livePhotoMode: CameraService.LivePhotoMode = .off
    var photoSettings: AVCapturePhotoSettings!
    var isSilentModeOn = false
    var photoQualityPrioritizationMode: AVCapturePhotoOutput.QualityPrioritization = .balanced

    @Published var recentImage: UIImage?
    @Published var isCameraBusy = false
    
    func waterMarkReceive(image: UIImage?) {
        self.waterMark = image
    }
    
    func toggleLivePhotoMode() {
        photoSettings = setUpPhotoSettings()
    }
    
    
    func setupCamera() {
        session.beginConfiguration()
        session.sessionPreset = .photo
        
        //Add Video input Device
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInUltraWideCamera, .builtInWideAngleCamera, .builtInTelephotoCamera], mediaType: .video, position: .back)
        
        for device in deviceDiscoverySession.devices {
            if device.deviceType == .builtInWideAngleCamera {
                videoDeviceInput = try? AVCaptureDeviceInput(device: device)
                break
            }
        }
        if session.canAddInput(videoDeviceInput) {
            session.addInput(videoDeviceInput)
        } else {
            print("비디오 장치를 추가 할 수 없습니다.")
        }
        
        //Add Audio input Device
        do {
            let audioDevice = AVCaptureDevice.default(for: .audio)
            let audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice!)
            if session.canAddInput(audioDeviceInput) {
                session.addInput(audioDeviceInput)
            } else {
                print("오디오 장치를 추가 할 수 없습니다.")
            }
        } catch {
            print(error.localizedDescription)
        }
        
        //Add the photo output
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            photoOutput.isLivePhotoCaptureEnabled = photoOutput.isLivePhotoCaptureSupported
            photoOutput.maxPhotoQualityPrioritization = .quality
            livePhotoMode = photoOutput.isLivePhotoCaptureSupported ? .on :.off
            self.configurePhotoOutput()
        }
        session.commitConfiguration()
        session.startRunning()
        
    }
    
    func configurePhotoOutput()  {
        let supportedMaxPhotoDimensions = self.videoDeviceInput.device.activeFormat.supportedMaxPhotoDimensions
        let largestDimension = supportedMaxPhotoDimensions.last
        self.photoOutput.maxPhotoDimensions = largestDimension!
        self.photoOutput.isLivePhotoCaptureEnabled = self.photoOutput.isLivePhotoCaptureSupported
        self.photoOutput.maxPhotoQualityPrioritization = .quality
        if #available(iOS 17.0, *) {
            self.photoOutput.isResponsiveCaptureEnabled = self.photoOutput.isResponsiveCaptureEnabled
            self.photoOutput.isFastCapturePrioritizationEnabled = self.photoOutput.isFastCapturePrioritizationSupported
            self.photoOutput.isAutoDeferredPhotoDeliveryEnabled = self.photoOutput.isAutoDeferredPhotoDeliverySupported
        }
        let photoSettings = self.setUpPhotoSettings()
        DispatchQueue.main.async {
            self.photoSettings = photoSettings
        }
    }
    
    func setUpPhotoSettings()  -> AVCapturePhotoSettings{
        var photoSettings = AVCapturePhotoSettings()
        
        //HEIF
        if self.photoOutput.availablePhotoCodecTypes.contains(AVVideoCodecType.hevc) {
            photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
        } else {
            photoSettings = AVCapturePhotoSettings()
        }
        
        //flash auto mode
        if self.flashMode == .on && self.videoDeviceInput.device.isFlashAvailable{
            photoSettings.flashMode = .auto
        }
        
        // Enable high-resolution photos
        photoSettings.maxPhotoDimensions = self.photoOutput.maxPhotoDimensions
        if !photoSettings.availablePreviewPhotoPixelFormatTypes.isEmpty {
            photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: photoSettings.availablePreviewPhotoPixelFormatTypes.first!]
        }
        
        //Live Photo Capture is not supported in movie mode
        if self.livePhotoMode == .on && self.photoOutput.isLivePhotoCaptureSupported {
            photoSettings.livePhotoMovieFileURL = livePhotoMovieUniqueTemporaryDirectoryFileURL()
        }
        photoSettings.photoQualityPrioritization = self.photoQualityPrioritizationMode
        return photoSettings
    }
    
    func livePhotoMovieUniqueTemporaryDirectoryFileURL() -> URL {
        let livePhotoMovieFileName = UUID().uuidString
        let livePhotoMovieFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent((livePhotoMovieFileName as NSString).appendingPathExtension("mov")!)
        let livePhotoMovieURL = NSURL.fileURL(withPath: livePhotoMovieFilePath)
        return livePhotoMovieURL
    }
    
    
    
    func requestAndCheckPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { [weak self] garented in
                if garented {
                    DispatchQueue.main.async {
                        self?.setupCamera()
                    }
                }
            })
        case .restricted:
            break
        case .authorized:
            setupCamera()
        default:
            print("권한이 없습니다.")
            break
        }
    }
    
    func capturePhoto() {
        if self.photoSettings == nil {
            print("No photoSettings to capture")
            return
        }

        let photoSettings = AVCapturePhotoSettings(from: self.photoSettings)
        
        if photoSettings.livePhotoMovieFileURL != nil {
            photoSettings.livePhotoMovieFileURL = livePhotoMovieUniqueTemporaryDirectoryFileURL()
        }
        photoSettings.flashMode = self.flashMode
        photoSettings.photoQualityPrioritization = .quality
        self.photoOutput.capturePhoto(with: photoSettings, delegate: self)
    }
    
    func savePhoto(_ imageData: Data) {
        let waterMark = self.waterMark
        guard let image = UIImage(data: imageData) else { return }
        guard let newImage = image.overlayWith(image: waterMark ?? UIImage()) else { return }
        
        UIImageWriteToSavedPhotosAlbum(newImage, nil, nil, nil)
        print("Saved Photo")
    }
    
    func zoom(_ zoom: CGFloat) {
        let factor = zoom < 1 ? 1 : zoom
        let device = self.videoDeviceInput.device
        
        do {
            try device.lockForConfiguration()
            device.videoZoomFactor = factor
            device.unlockForConfiguration()
            
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func flipCamera() {
        let currentDevicePosition = self.videoDeviceInput.device.position
        let changedDevicePosition: AVCaptureDevice.Position
        
        switch currentDevicePosition {
        case .unspecified, .front :
            changedDevicePosition = .back
        case .back :
            changedDevicePosition = .front
        default:
            changedDevicePosition = .back
        }
        
        if let videoDevice = AVCaptureDevice
            .default(.builtInWideAngleCamera, for: .video, position: changedDevicePosition) {
            do {
                let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
                self.session.beginConfiguration()
                
                //Sesssion에서 기존 장치정보 정보 지우기
                if let inputs = session.inputs as? [AVCaptureDeviceInput] {
                    for input in inputs {
                        self.session.removeInput(input)
                    }
                }
                
                //새로운 장치 정보 넣기
                if self.session.canAddInput(videoDeviceInput) {
                    self.session.addInput(videoDeviceInput)
                    self.videoDeviceInput = videoDeviceInput
                } else {
                    self.session.addInput(self.videoDeviceInput)
                }
                
                if let connection = self.photoOutput.connection(with: .video) {
                    session.sessionPreset = .high
                    if connection.isVideoStabilizationSupported {
                        connection.preferredVideoStabilizationMode = .auto
                    }
                }
                photoOutput.maxPhotoQualityPrioritization = .quality
                self.session.commitConfiguration()
                
            } catch {
                print("Error occurred: \(error)")
            }
        }
    }
    
    func switchToLens(position: AVCaptureDevice.DeviceType) {
        session.beginConfiguration()
        guard let currentInputs = session.inputs as? [AVCaptureDeviceInput] else { return }
        for input in currentInputs {
            self.session.removeInput(input)
        }
        
        let deviceDescoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [position], mediaType: .video, position: .back)
        if let device = deviceDescoverySession.devices.first,
           let newInput = try? AVCaptureDeviceInput(device: device) {
            if session.canAddInput(newInput) {
                session.addInput(newInput)
            }
        }
        session.commitConfiguration()
    }
    
}

extension Camera: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, willBeginCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        self.isCameraBusy = true
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        if isSilentModeOn {
            AudioServicesDisposeSystemSoundID(1108)
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        if isSilentModeOn {
            AudioServicesDisposeSystemSoundID(1108)
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: (any Error)?) {
        guard let imageData = photo.fileDataRepresentation() else { return }
        self.recentImage = UIImage(data: imageData)
        self.savePhoto(imageData)
        self.isCameraBusy = false
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishRecordingLivePhotoMovieForEventualFileAt outputFileURL: URL, resolvedSettings: AVCaptureResolvedPhotoSettings) {
        
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingLivePhotoToMovieFileAt outputFileURL: URL, duration: CMTime, photoDisplayTime: CMTime, resolvedSettings: AVCaptureResolvedPhotoSettings, error: (any Error)?) {
        
    }
    
    @available(iOS 17.0, *)
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCapturingDeferredPhotoProxy deferredPhotoProxy: AVCaptureDeferredPhotoProxy?, error: (any Error)?) {
        if let error = error {
            print("Error capturing deferred photo \(error)")
            return
        }
        self.photoData = deferredPhotoProxy?.fileDataRepresentation()
    }
}

extension UIImage {
    func overlayWith(image: UIImage) -> UIImage? {
        let newSize = CGSize(width: size.width, height: size.height)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        
        draw(in: CGRect(origin: .zero, size: size))
        image.draw(in: CGRect(origin: CGPoint(x: size.width - 700, y: size.height - 1200), size: .init(width: 300, height: 150)))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
}

extension View {
    func viewToImage(view: some View) -> UIImage? {
        var image = UIImage()
        let controller = UIHostingController(rootView: view)
        controller.view.frame = CGRect(x: 0, y: CGFloat(Int.max), width: 1, height: 1)
        if let view = controller.view {
            let contentSize = view.intrinsicContentSize
            view.bounds = CGRect(origin: .zero, size: contentSize)
            view.backgroundColor = .clear
            view.sizeToFit()
            let renderer = UIGraphicsImageRenderer(size: contentSize)
            image = renderer.image { _ in
                view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
            }
        }
        return image
    }
    
    func viewRotationEffect(deg: Double) -> some View{
        self.rotationEffect(Angle(degrees: deg))
            .animation(.easeInOut(duration: 0.5), value: deg)
    }
}
