import SwiftUI
import UIKit
import AVFoundation
import Photos
import CoreLocation


class Camera: NSObject, ObservableObject, AVCapturePhotoOutputReadinessCoordinatorDelegate {
    
    var session = AVCaptureSession()
    var videoDeviceInput: AVCaptureDeviceInput!
    var photoOutput = AVCapturePhotoOutput()
    var photoData: Data?
    var waterMark: UIImage?
    var flashMode: AVCaptureDevice.FlashMode = .off
    var livePhotoMode: LivePhotoMode = .off
    var photoSettings: AVCapturePhotoSettings!
    var isSilentModeOn = false
    var photoQualityPrioritizationMode: AVCapturePhotoOutput.QualityPrioritization = .balanced
    let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInUltraWideCamera, .builtInWideAngleCamera, .builtInTelephotoCamera], mediaType: .video, position: .back)
    let sessionQueue = DispatchQueue(label: "session queue")
    var inProgressPhotoCaptrueDelegates = [Int64: PhotoCaptureProcessorDelegate]()
    var livePhotoCompanionMovieURL: URL?
    let locationManger = CLLocationManager()
    var previewView = CameraPreview.VideoPreviewView()
    
    var photoOuputReadinessCoordinator: AVCapturePhotoOutputReadinessCoordinator!
    private var videoDeviceRotationCoordinator: AVCaptureDevice.RotationCoordinator!
    private var videoRotationAngleForHorizonLevelPreviewObservation: NSKeyValueObservation?
    
    @Published var recentImage: UIImage?
    @Published var isCameraBusy = false

    func waterMarkReceive(image: UIImage) {
        self.waterMark = image
    }
    
    func toggleLivePhotoMode() {
        sessionQueue.async {
            let photoSettings = self.setUpPhotoSettings()
            DispatchQueue.main.async {
                self.photoSettings = photoSettings
                self.didFinish()
            }
        }
    }
    
    func startCamera() {
        session.startRunning()
    }
    
    func stopCamera() {
        session.stopRunning()
    }
    
    func setupCamera() {
        if locationManger.authorizationStatus == .notDetermined {
            locationManger.requestWhenInUseAuthorization()
        }
        session.beginConfiguration()
        session.sessionPreset = .photo
    
        //Add Video input Device
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
            session.commitConfiguration()
            return
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
        
        //Add the photoOutput
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            photoOutput.isLivePhotoCaptureEnabled = photoOutput.isLivePhotoCaptureSupported
            photoOutput.maxPhotoQualityPrioritization = .quality
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
            print("No photo settings to capture")
            return
        }
        let photoSettings = AVCapturePhotoSettings(from: self.photoSettings)
        if photoSettings.livePhotoMovieFileURL != nil {
            photoSettings.livePhotoMovieFileURL = livePhotoMovieUniqueTemporaryDirectoryFileURL()
        }

        sessionQueue.async {
            if let photoOuputConnection = self.photoOutput.connection(with: .video) {
                photoOuputConnection.videoRotationAngle = UIDevice.current.orientation.videoRotationAngel
            }
            self.photoOutput.capturePhoto(with: photoSettings, delegate: self)
        }
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
        sessionQueue.async {
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
                    
                    //Session에서 기존 장치정보 정보 지우기
                    if let inputs = self.session.inputs as? [AVCaptureDeviceInput] {
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
                        self.session.sessionPreset = .high
                        if connection.isVideoStabilizationSupported {
                            connection.preferredVideoStabilizationMode = .auto
                        }
                    }
                    self.photoOutput.maxPhotoQualityPrioritization = .quality
                    self.session.commitConfiguration()
                    
                } catch {
                    print("Error occurred: \(error)")
                }
            }
        }
    }
    
    func switchToLens(position: AVCaptureDevice.DeviceType) {
        sessionQueue.async {
            guard let currentPosition = self.videoDeviceInput?.device.position else { return }
            let preferredPosition: AVCaptureDevice.Position
            
            switch currentPosition {
            case .unspecified, .front:
                preferredPosition = .back
            case .back:
                preferredPosition = .back
            default:
                preferredPosition = .back
            }
            guard let videoDevice = AVCaptureDevice.default(position, for: .video, position: preferredPosition) else { return }
            
            do {
                let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
                self.session.beginConfiguration()
                
                //Session에서 기존 장치정보 정보 지우기
                if let inputs = self.session.inputs as? [AVCaptureDeviceInput] {
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
                    self.session.sessionPreset = .photo
                    if connection.isVideoStabilizationSupported {
                        connection.preferredVideoStabilizationMode = .auto
                    }
                }
                self.photoOutput.maxPhotoQualityPrioritization = .quality
                self.configurePhotoOutput()
                self.session.commitConfiguration()
            }
            catch {
                print("Error to SwitchToLens \(error.localizedDescription)")
            }
        }
    }
    
    func didFinish() {
        if let livePhotoCompanionMoviePath = livePhotoCompanionMovieURL?.path {
            if FileManager.default.fileExists(atPath: livePhotoCompanionMoviePath) {
                do {
                    try FileManager.default.removeItem(atPath: livePhotoCompanionMoviePath)
                } catch {
                    print("파일을 지울 수 없습니다. \(livePhotoCompanionMoviePath)")
                }
            }
        }
    }
    
    
    func createDeviceRotationCoordinator() {
        videoDeviceRotationCoordinator = AVCaptureDevice.RotationCoordinator(device: videoDeviceInput.device, previewLayer: previewView.videoPreviewLayer)
        previewView.videoPreviewLayer.connection?.videoRotationAngle = videoDeviceRotationCoordinator.videoRotationAngleForHorizonLevelPreview
        videoRotationAngleForHorizonLevelPreviewObservation = videoDeviceRotationCoordinator.observe(\.videoRotationAngleForHorizonLevelPreview, options: .new) { _, change in
            guard let videoRotationAngleForHorizonLevelPreview = change.newValue else { return }
            self.previewView.videoPreviewLayer.connection?.videoRotationAngle = videoRotationAngleForHorizonLevelPreview
        }
    }
    
    func focus(with focusMode: AVCaptureDevice.FocusMode, exposureMode: AVCaptureDevice.ExposureMode, at devicePoint: CGPoint, monitorSubjectAreaChange: Bool) {
        sessionQueue.async {
            let device = self.videoDeviceInput.device
            do {
                try device.lockForConfiguration()
                //초점설정
                if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(focusMode) {
                    device.focusPointOfInterest = devicePoint
                    device.focusMode = focusMode
                }
                //노출설정
                if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(exposureMode) {
                    device.exposurePointOfInterest = devicePoint
                    device.exposureMode = exposureMode
                }
                device.isSubjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
                device.unlockForConfiguration()
                
            } catch {
                print("장치의 초점에 접근할 수 없습니다. \(error.localizedDescription)")
            }
        }
    }
    
    func mergeImage(topImage: UIImage, bottomImage: UIImage) -> UIImage? {
        let size = CGSize(width: bottomImage.size.width, height: bottomImage.size.height)
        UIGraphicsBeginImageContext(size)
        
        let area = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        bottomImage.draw(in: area)
        topImage.draw(in: area, blendMode: .normal, alpha: 1)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
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
        self.photoData = photo.fileDataRepresentation()
        //받은 사진데이터 합성하기 -> livePhoto 사용시 예외 처리
        /*
        guard let image = UIImage(data: photoData ?? Data()) else { return }
        guard let mergeImage = mergeImage(topImage: waterMark ?? UIImage(), bottomImage: image) else { return }
        self.photoData = mergeImage.jpegData(compressionQuality: 1.0)
         */
    }
    
    @available(iOS 17.0, *)
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCapturingDeferredPhotoProxy deferredPhotoProxy: AVCaptureDeferredPhotoProxy?, error: (any Error)?) {
        if let error = error {
            print("Error capturing deferred photo \(error)")
            return
        }
        self.photoData = deferredPhotoProxy?.fileDataRepresentation()
    }
    
    //라이브포토 레코딩이 끝남
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishRecordingLivePhotoMovieForEventualFileAt outputFileURL: URL, resolvedSettings: AVCaptureResolvedPhotoSettings) {
        
    }
    
    //라이브포토 프로세싱 끝남
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingLivePhotoToMovieFileAt outputFileURL: URL, duration: CMTime, photoDisplayTime: CMTime, resolvedSettings: AVCaptureResolvedPhotoSettings, error: (any Error)?) {
        if error != nil {
            print("Error processing Live Photo companion movie \(String(describing: error))")
            return
        }
        livePhotoCompanionMovieURL = outputFileURL
    }
    //캡쳐 끝나고 저장하기
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
                PHPhotoLibrary.shared().performChanges {
                    //일반 사진 저장
                    let options = PHAssetResourceCreationOptions()
                    let createRequest = PHAssetCreationRequest.forAsset()
                    options.uniformTypeIdentifier = self.photoSettings.processedFileType.map {
                        $0.rawValue
                    }
                    var resourceType = PHAssetResourceType.photo
                    if resolvedSettings.deferredPhotoProxyDimensions.width > 0 && resolvedSettings.deferredPhotoProxyDimensions.height > 0 {
                        resourceType = PHAssetResourceType.photoProxy
                    }
                    createRequest.addResource(with: resourceType, data: self.photoData!, options: options)
                    createRequest.location = self.locationManger.location
                    
                    //라이브포토 사진 저장
                    if let livePhotoCompanionMovieURL = self.livePhotoCompanionMovieURL, self.livePhotoMode == .on {
                        let livePhotoCompanionMovieFileOption = PHAssetResourceCreationOptions()
                        livePhotoCompanionMovieFileOption.shouldMoveFile = true
                        createRequest.addResource(with: .pairedVideo, fileURL: livePhotoCompanionMovieURL, options: livePhotoCompanionMovieFileOption)
                    }
                } completionHandler: { success, error in
                    if let error = error {
                        print("Photo Library에 저장하는 도중 에러가 발생했습니다. \(error)")
                    } else {
                        print("저장 성공:\(success)")
                    }
                    self.didFinish()
                }
                //사진 썸네일처리
                DispatchQueue.main.async {
                    self.recentImage = UIImage(data: self.photoData!)
                    self.isCameraBusy = false
                }
            } else {
                self.didFinish()
            }
        }
    }
}


