//
//  CameraService.swift
//  CustomCamera
//
//  Created by window1 on 7/27/24.
//

import AVFoundation
import CoreImage
import UIKit
import OSLog
import CoreLocation

class CameraService: NSObject {
    private let captureSession = AVCaptureSession()
    private var isCaptureSessionConfigured = false
    private var deviceInput: AVCaptureDeviceInput?
    private var photoOutput: AVCapturePhotoOutput?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var sessionQueue: DispatchQueue!
    private var locationManger = CLLocationManager()
    
    private var allCaptureDevices: [AVCaptureDevice] {
        AVCaptureDevice.DiscoverySession(deviceTypes: [
            .builtInTrueDepthCamera,
            .builtInDualCamera,
            .builtInDualWideCamera,
            .builtInWideAngleCamera,
            .builtInDualWideCamera
        ], mediaType: .video, position: .unspecified).devices
    }
    
    private var frontCaptureDevices: [AVCaptureDevice] {
        allCaptureDevices.filter {
            $0.position == .front
        }
    }
    
    private var backCaptureDevices: [AVCaptureDevice] {
        allCaptureDevices.filter {
            $0.position == .back
        }
    }
    //장치가 추가 되면 하나씩 넣기
    private var captureDevices: [AVCaptureDevice] {
        var devices = [AVCaptureDevice]()
        #if os(macOS) || (os(iOS) && targetEnvironment(macCatalyst))
        devices += allCaptureDevices
        #else
        if let backDevice = backCaptureDevices.first {
            devices += [backDevice]
        }
        if let frontDevice = frontCaptureDevices.first {
            devices += [frontDevice]
        }
        #endif
        return devices
    }
    //장치 연결된 상태 확인
    private var availableCaptureDevices: [AVCaptureDevice] {
        captureDevices
            .filter({ $0.isConnected })
            .filter({ !$0.isSuspended })
    }
    
    private var captureDevice: AVCaptureDevice? {
        didSet {
            guard let captureDevice = captureDevice else { return }
            sessionQueue.async {
                self.updateSessionForCaptureDevice(captureDevice)
            }
        }
    }
    
    private var audioDevice: AVCaptureDevice? {
        didSet {
            guard let audioDevice = audioDevice else { return }
            sessionQueue.async {
                self.updateSessionForCaptureDevice(audioDevice)
            }
        }
    }
    
    var isRunning: Bool {
        captureSession.isRunning
    }
    
    var isUsingFrontCaptureDevice: Bool {
        guard let captureDevice = captureDevice else { return false }
        return frontCaptureDevices.contains(captureDevice)
    }
    
    var isUsingBackCaptureDevice: Bool {
        guard let captureDevice = captureDevice else { return false }
        return backCaptureDevices.contains(captureDevice)
    }
    
    private var addToPhotoStream: ((AVCapturePhoto) -> Void)?
    
    private var addToPreviewStream: ((CIImage) -> Void)?
    
    var isPreviewPaused = false
    
    lazy var previewStream: AsyncStream<CIImage> = {
        AsyncStream { continuation in
            addToPreviewStream = { ciImage in
                if !self.isPreviewPaused {
                    continuation.yield(ciImage)
                }
            }
        }
    }()
    
    lazy var photoStream: AsyncStream<AVCapturePhoto> = {
        AsyncStream { continuation in
            addToPhotoStream = { photo in
                continuation.yield(photo)
            }
        }
    }()
    
    //MARK: method
    
    override init() {
        super.init()
        initialize()
    }
    
    private func initialize() {
        //세션큐
        sessionQueue = DispatchQueue(label: "session queue")
        //장치 확인
        captureDevice = availableCaptureDevices.first ?? AVCaptureDevice.default(for: .video)
        audioDevice = AVCaptureDevice.default(for: .audio)
        //현재 화면이 회전하면 알림
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        //화면 회전시 selector에 있는 함수로 이벤트 정보 보내기
        NotificationCenter.default.addObserver(self, selector: #selector(updateForDeviceOrientation), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    private func configureCaptureSession(completionHandler: (_ success: Bool) -> Void) {
        
        if locationManger.authorizationStatus == .notDetermined {
            locationManger.requestWhenInUseAuthorization()
        }
        var success = false
        self.captureSession.beginConfiguration()
        
        defer {
            self.captureSession.commitConfiguration()
            completionHandler(success)
        }
        ///오디오 장치 추가(Live Photo)
        guard let audioDevice = audioDevice,
              let audioDeviceInput = try? AVCaptureDeviceInput(device: audioDevice)
        else {
            logger.error("지원하는 오디오 장치가 없다")
            return
        }
        guard captureSession.canAddInput(audioDeviceInput) else {
            logger.error("캡쳐 세션에 audiodeviceInput 을 추가 할 수 없습니다.")
            return
        }
        captureSession.addInput(audioDeviceInput)
        
        ///비디오 장치 추가
        guard let captureDevice = captureDevice,
              let videoDeviceInput = try? AVCaptureDeviceInput(device: captureDevice)
                
        else {
            logger.error("지원하는 비디오 장치가 없다")
            return
        }
        
        let photoOutput = AVCapturePhotoOutput()
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "VideoDataOutputQueue"))
        
        guard captureSession.canAddInput(videoDeviceInput) else {
            logger.error("캡쳐 세션에 deviceInput 을 추가 할 수 없습니다.")
            return }
        guard captureSession.canAddOutput(photoOutput) else {
            logger.error("캡쳐 세션에 photoOutput 을 추가 할 수 없습니다.")
            return }
        guard captureSession.canAddOutput(videoOutput) else {
            return
        }
        
        captureSession.addInput(videoDeviceInput)
        captureSession.addOutput(photoOutput)
        captureSession.addOutput(videoOutput)
        
        self.deviceInput = videoDeviceInput
        self.photoOutput = photoOutput
        self.videoOutput = videoOutput
    
        ///photoOutput 설정
        photoOutput.maxPhotoDimensions = videoDeviceInput.device.activeFormat.supportedMaxPhotoDimensions.last!
        photoOutput.maxPhotoQualityPrioritization = .quality
        photoOutput.isLivePhotoCaptureEnabled = photoOutput.isLivePhotoCaptureSupported
        
        updateVideoOutputConnection()
        
        isCaptureSessionConfigured = true
        success = true
    }
    
    private func checkAuthorization() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            logger.debug("카메라 접근 인증됨")
            return true
        case .notDetermined:
            sessionQueue.suspend()
            let status = await AVCaptureDevice.requestAccess(for: .video)
            sessionQueue.resume()
            return status
        case .denied:
            logger.debug("카메라 접근이 거절됨")
            return false
        case .restricted:
            logger.debug("카메라 라이브러리 접근이 제한됨")
            return false
        @unknown default:
            return false
        }
    }

    private func deviceInputFor(device: AVCaptureDevice?) -> AVCaptureDeviceInput? {
        guard let validDevice = device else { return nil }
        do {
            return try AVCaptureDeviceInput(device: validDevice)
        } catch let error {
            logger.error("Error getting capture device input: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func updateSessionForCaptureDevice(_ captureDevice: AVCaptureDevice) {
        guard isCaptureSessionConfigured else { return }
        
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }

        for input in captureSession.inputs {
            if let deviceInput = input as? AVCaptureDeviceInput {
                captureSession.removeInput(deviceInput)
            }
        }
        
        if let deviceInput = deviceInputFor(device: captureDevice) {
            if !captureSession.inputs.contains(deviceInput), 
                captureSession.canAddInput(deviceInput) {
                captureSession.addInput(deviceInput)
            }
        }
        
        updateVideoOutputConnection()
    }
    
    @objc func updateForDeviceOrientation() {
        
    }
    
    func start() async {
        ///권한확인
        let authroized = await checkAuthorization()
        guard authroized else {
            logger.error("카메라 접근 권한이 없습니다.")
            return
        }
        ///세션이 활성화되지 않으면 활성화하기
        if isCaptureSessionConfigured {
            if !captureSession.isRunning {
                sessionQueue.async {
                    self.captureSession.startRunning()
                }
            }
            return
        }
        ///세션이 없는 경우
        sessionQueue.async { [self] in
            self.configureCaptureSession(completionHandler: { success in
                guard success else { return }
                self.captureSession.startRunning()
            })
        }
    }
    
    func stop() {
        guard isCaptureSessionConfigured else { return }
        if captureSession.isRunning {
            sessionQueue.async {
                self.captureSession.stopRunning()
            }
        }
    }
    
    func switchCaptureDevice() {
        if let captureDevice = captureDevice,
           let index = availableCaptureDevices.firstIndex(of: captureDevice) {
            let nextIndex = (index + 1) % availableCaptureDevices.count
            self.captureDevice = availableCaptureDevices[nextIndex]
        } else {
            self.captureDevice = AVCaptureDevice.default(for: .video)
        }
    }
    
    func switchBackCaptureDevice(lens: AVCaptureDevice.DeviceType) {
        ///현재 장치의 종류 확인
    }
    
    func updateVideoOutputConnection() {
        if let videoOutput = videoOutput,
           let videoOuputConnection = videoOutput.connection(with: .video) {
            if videoOuputConnection.isVideoMirroringSupported {
                videoOuputConnection.isVideoMirrored = isUsingFrontCaptureDevice
            }
        }
    }
    
    private func videoOrientationFor(_ deviceOrientation: UIDeviceOrientation) -> AVCaptureVideoOrientation? {
        switch deviceOrientation {
        case .portrait: return AVCaptureVideoOrientation.portrait
        case .portraitUpsideDown: return AVCaptureVideoOrientation.portraitUpsideDown
        case .landscapeLeft: return AVCaptureVideoOrientation.landscapeRight
        case .landscapeRight: return AVCaptureVideoOrientation.landscapeLeft
        default: return nil
        }
    }
    
    private var deviceOrientation: UIDeviceOrientation {
        var orientation = UIDevice.current.orientation
        if orientation == UIDeviceOrientation.unknown{
            orientation = UIScreen.main.orientation
        }
        return orientation
    }

    func takePhoto() {
        guard let photoOutput = self.photoOutput else { return }
        sessionQueue.async {
            var photoSettings = AVCapturePhotoSettings()
            if photoOutput.availablePhotoCodecTypes.contains(AVVideoCodecType.hevc) {
                photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
            }
            let isFlashAvailable = self.deviceInput?.device.isFlashAvailable ?? false
            photoSettings.flashMode = isFlashAvailable ? .auto : .off
            photoSettings.maxPhotoDimensions = self.photoOutput?.maxPhotoDimensions ?? .init()
            
            if let previewPhotoPixelFormatType = photoSettings.availablePreviewPhotoPixelFormatTypes.first {
                photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPhotoPixelFormatType]
            }
            photoSettings.photoQualityPrioritization = .balanced
            
            if let photoOutputVideoConnection = photoOutput.connection(with: .video) {
                if photoOutputVideoConnection.isVideoOrientationSupported,
                    let videoOrientation = self.videoOrientationFor(self.deviceOrientation) {
                    photoOutputVideoConnection.videoOrientation = videoOrientation
                }
            }
            photoOutput.capturePhoto(with: photoSettings, delegate: self)
        }
    }
    
    func setUpPhotoSetting() {
        
    }
    
}

extension CameraService: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: (any Error)?) {
        if let error = error {
            logger.error("Error capturing photo: \(error.localizedDescription)")
            print("Error capturing photo: \(error.localizedDescription)")
            return
        }
        addToPhotoStream?(photo)
    }
}

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = sampleBuffer.imageBuffer else { return }
        if connection.isVideoOrientationSupported,
           let videoOrientation = videoOrientationFor(deviceOrientation) {
            connection.videoOrientation = videoOrientation
        }

        addToPreviewStream?(CIImage(cvPixelBuffer: pixelBuffer))
    }
}


fileprivate extension UIScreen {

    var orientation: UIDeviceOrientation {
        let point = coordinateSpace.convert(CGPoint.zero, to: fixedCoordinateSpace)
        if point == CGPoint.zero {
            return .portrait
        } else if point.x != 0 && point.y != 0 {
            return .portraitUpsideDown
        } else if point.x == 0 && point.y != 0 {
            return .landscapeRight //.landscapeLeft
        } else if point.x != 0 && point.y == 0 {
            return .landscapeLeft //.landscapeRight
        } else {
            return .unknown
        }
    }
}

fileprivate let logger = Logger(subsystem: "G2.CustomCamera", category: "PhotoCollection")

