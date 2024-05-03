
import Foundation
import AVFoundation
import Photos
import UIKit

public struct Photo: Identifiable, Equatable {
    public var id: String
    public var originData: Data
    
    public init(id: String = UUID().uuidString, originData: Data) {
        self.id = id
        self.originData = originData
    }
    
    public var compressdData: Data? {
        ImageResizer(targetWidth: 800).resize(data: originData)?.jpegData(compressionQuality: 0.5)
    }
    
    public var thumbnailData: Data? {
        ImageResizer(targetWidth: 100).resize(data: originData)?.jpegData(compressionQuality: 0.5)
    }
    
    public var thumbnailImage: UIImage? {
        guard let data = thumbnailData else { return nil }
        return UIImage(data: data)
    }
    
    public var image: UIImage? {
        guard let data = compressdData else { return nil }
        return UIImage(data: data)
    }
}

public struct AlertError {
    public var title: String = ""
    public var message: String = ""
    public var primaryButtonTitle = "Accept"
    public var secondaryButtonTitle: String?
    public var primaryAction: (() -> ())?
    public var secondaryAction: (() -> ())?
    
    public init(title: String = "", message: String = "", primaryButtonTitle: String = "Accept", secondaryButtonTitle: String? = nil, primaryAction: ( () -> Void)? = nil, secondaryAction: ( () -> Void)? = nil) {
        self.title = title
        self.message = message
        self.primaryButtonTitle = primaryButtonTitle
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
    }
}

public class CameraService: ObservableObject {
    
    typealias PhotoCaptureSessionID = String
    
    @Published public var flashMode: AVCaptureDevice.FlashMode = .off
    @Published public var shouldShowAlertView = false
    @Published public var shouldShowSpinner = false
    @Published public var willCapturePhoto = false
    @Published public var isCameraButtonDisabled = true
    @Published public var isCameraUnavailable = true
    @Published public var photo: Photo?
    
    public var alertError = AlertError()
    
    
    public let session = AVCaptureSession()
    
    var isSessionRunning = false
    var isConfigured = false
    var setupResult: SessionSetupResult = .success
    
    private let sessionQueue = DispatchQueue(label: "camera session queue")
    
    @objc dynamic var videoDeviceInput: AVCaptureDeviceInput!
    
    private let videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera], mediaType: .video, position: .unspecified)
    
    private let photoOutput = AVCapturePhotoOutput()
    
    private var inProgressPhotoCaptureDelegates = [Int64: PhotoCaptureProcessor]()
    
    private var keyValueObservations = [NSKeyValueObservation]()
    
    public func configure() {
        sessionQueue.async {
            self.configureSession()
        }
    }
    //MARK: - 권환학인
    public func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break;
        case .notDetermined:
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                if !granted {
                    self.setupResult = .notAuthorized
                }
                self.sessionQueue.resume()
            })
        default:
            
            setupResult = .notAuthorized
            
            DispatchQueue.main.async {
                self.alertError = AlertError(title: "카메라 접근", message: "CustomCamera에서 카메라 기능 접근할 권한이 없습니다. 설정에서 접근권한을 변경해주세요", primaryButtonTitle: "설정", secondaryButtonTitle: nil, primaryAction: {
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!,
                                                                     options: [:], completionHandler: nil)
                    
                }, secondaryAction: nil)
                self.shouldShowAlertView = true
                self.isCameraUnavailable = true
                self.isCameraButtonDisabled = true
            }
            
        }
    }
    //카메라 장치가 있는지 확인
    private func configureSession() {
        if setupResult != .success {
            return
        }
        session.beginConfiguration()
        session.sessionPreset = .photo
        
        do {
            var defaultVideoDevice: AVCaptureDevice?
            if let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                defaultVideoDevice = backCameraDevice
            } else if let frontCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
                defaultVideoDevice = frontCameraDevice
            }
            
            guard let videoDevice = defaultVideoDevice else {
                print("촬영 기능을 이용 할 수 없습니다.")
                setupResult = .configurationFaild
                session.commitConfiguration()
                return
            }
            
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
            } else {
                print("input Session에 촬영 장치를 추가하지 못했습니다.")
                setupResult = .configurationFaild
                session.commitConfiguration()
                return
            }
            
        } catch {
            print(error.localizedDescription)
            setupResult = .configurationFaild
            session.commitConfiguration()
            return
        }
        
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        
            photoOutput.maxPhotoQualityPrioritization = .quality
        } else {
            print("output session에서 촬영 장치를 추가하지 못했습니다.")
            setupResult = .configurationFaild
            session.commitConfiguration()
            return
        }
        
        session.commitConfiguration()
        isConfigured = true
        self.start()
    }
    //권한 승인을 받았는지 확인하기
    public func start() {
        sessionQueue.async {
            if !self.isSessionRunning && self.isConfigured {
                switch self.setupResult {
                case .success:
                    self.session.startRunning()
                    self.isSessionRunning = self.session.isRunning
                    
                    if self.session.isRunning {
                        DispatchQueue.main.async {
                            self.isCameraButtonDisabled = false
                            self.isCameraUnavailable = false
                        }
                    }
                case .configurationFaild, .notAuthorized:
                    print("카메라를 사용하기 위한 사용자 승인을 받지 못했다.")
                    
                    DispatchQueue.main.async {
                        self.alertError = AlertError(title: "카메라 오류", message: "장치에 있는 카메라를 사용할 수 없거나 사용권한이 없습니다.", primaryButtonTitle: "확인", secondaryButtonTitle: nil, primaryAction: nil, secondaryAction: nil)
                        self.shouldShowAlertView = true
                        self.isCameraButtonDisabled = true
                        self.isCameraUnavailable = true
                    }
                    
                }
            }
        }
    }
    //캡쳐하고 있는 프리뷰를 멈춤
    public func stop(completion: (() ->())? = nil) {
        sessionQueue.async {
            guard self.isSessionRunning else { return }
            if self.setupResult == .success {
                self.session.stopRunning()
                self.isSessionRunning = self.session.isRunning
                
                if !self.session.isRunning {
                    DispatchQueue.main.async {
                        self.isCameraButtonDisabled = true
                        self.isCameraUnavailable = true
                        completion?()
                    }
                }
            }
            
        }
    }
    //카메라 전환
    public func changeCamera() {
        DispatchQueue.main.async {
            self.isCameraButtonDisabled = true
        }
        sessionQueue.async {
            let currentVideoDevice = self.videoDeviceInput.device
            let currentPosition = currentVideoDevice.position
            
            let preferredPosition: AVCaptureDevice.Position
            let preferredDeviceType: AVCaptureDevice.DeviceType
            
            switch currentPosition {
            case .unspecified, .front:
                preferredPosition = .back
                preferredDeviceType = .builtInWideAngleCamera
            case .back:
                preferredPosition = .front
                preferredDeviceType = .builtInWideAngleCamera
            @unknown default:
                print("알 수 없는 카메라입니다.")
                preferredPosition = .back
                preferredDeviceType = .builtInWideAngleCamera
                return
            }
            let devices = self.videoDeviceDiscoverySession.devices
            var newVideoDevice: AVCaptureDevice? = nil
            
            if let device = devices.first(where: { $0.position == preferredPosition && $0.deviceType == preferredDeviceType }) {
                newVideoDevice = device
            } else if let device = devices.first(where:  { $0.position == preferredPosition }){
                newVideoDevice = device
            }
            
            if let videoDevice = newVideoDevice {
                do {
                    let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
                    
                    self.session.beginConfiguration()
                    self.session.removeInput(self.videoDeviceInput)
                    
                    if self.session.canAddInput(videoDeviceInput) {
                        self.session.addInput(videoDeviceInput)
                        self.videoDeviceInput = videoDeviceInput
                    } else {
                        self.session.addInput(self.videoDeviceInput)
                    }
                    
                    if let connection = self.photoOutput.connection(with: .video) {
                        if connection.isVideoMirroringSupported {
                            connection.preferredVideoStabilizationMode = .auto
                        }
                    }
                    self.photoOutput.maxPhotoQualityPrioritization = .quality
                    self.session.commitConfiguration()
                } catch {
                    print("Error occurred whild creating video device input: \(error)")
                }
            }
            DispatchQueue.main.async {
                self.isCameraButtonDisabled = false
            }
        }
    }
    //카메라 포커스
    public func focus(at focusPoint: CGPoint) {
        let device = self.videoDeviceInput.device
        do {
            try device.lockForConfiguration()
            if device.isFocusPointOfInterestSupported {
                device.focusPointOfInterest = focusPoint
                device.exposurePointOfInterest = focusPoint
                device.exposureMode = .continuousAutoExposure
                device.focusMode = .continuousAutoFocus
                device.unlockForConfiguration()
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    //카메라 줌
    public func setZoom(zoom: CGFloat) {
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
    //카메라 캡쳐 처리
    public func capturePhoto() {
        if setupResult != .configurationFaild {
            isCameraButtonDisabled = true
            
            sessionQueue.async {
                guard let photoOutputConnection = self.photoOutput.connection(with: .video) else { return }
                if #available(iOS 17.0, *) {
                    photoOutputConnection.videoRotationAngle = 90
                } else {
                    // Fallback on earlier versions
                    photoOutputConnection.videoOrientation = .portrait
                }
                var photoSettings = AVCapturePhotoSettings()
                
                if self.photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                    photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
                }
                
                if self.videoDeviceInput.device.isFlashAvailable {
                    photoSettings.flashMode = self.flashMode
                }
                
                if !photoSettings.availablePreviewPhotoPixelFormatTypes.isEmpty {
                    photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: photoSettings.availablePreviewPhotoPixelFormatTypes.first!]
                }
                photoSettings.photoQualityPrioritization = .quality
                
                let photoCaptureProcessor = PhotoCaptureProcessor(with: photoSettings, willCapturePhotoAnimation: { [weak self] in
                    DispatchQueue.main.async {
                        self?.willCapturePhoto = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self?.willCapturePhoto = false
                    }
                }, completionHandler: { PhotoCaptureProcessor in
                    
                    if let data = PhotoCaptureProcessor.photoData {
                        self.photo = Photo(originData: data)
                        print("Passing Photo")
                    } else {
                        print("No Photo Data")
                    }
                    self.isCameraButtonDisabled = false
                    
                    self.sessionQueue.async {
                        self.inProgressPhotoCaptureDelegates[PhotoCaptureProcessor.requestedPhotoSettings.uniqueID] = nil
                    }
                }, photoProcessingHandler: { [weak self] animate in
                    self?.shouldShowSpinner = animate
                })
                self.inProgressPhotoCaptureDelegates[photoCaptureProcessor.requestedPhotoSettings.uniqueID] = photoCaptureProcessor
                self.photoOutput.capturePhoto(with: photoSettings, delegate: photoCaptureProcessor)
            }
        }
    }
}

