//
//  CameraService.swift
//  CustomCamera
//
//  Created by window1 on 3/30/24.
//

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
        self.secondaryButtonTitle = secondaryButtonTitle
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
    @Published public var isCameraButtonDisable = true
    @Published public var isCameraUnavailable = true
    @Published public var photo: Photo?
    
    public let session = AVCaptureSession()
    public var alertError = AlertError()
    
    private var isSessionRunning = false
    private var isConfigured = false
    private var setupResult: SessionSetupResult = .success
    private var sessionQueue = DispatchQueue(label: "camera session queue")
    
    //@objc dynamic var videoDeviceInput: AVCaptureDeviceInput
    
    private let videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera], mediaType: .video, position: .unspecified)
    
    private let photoOutput = AVCapturePhotoOutput()
    
    //private var inProgressPhotoCaptureDelegates = [Int64: PhotoCaptureProcessor()]
    
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
                self.isCameraButtonDisable = true
            }
            
        }
    }
    
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
            }
            else if let frontCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
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
            
            photoOutput.maxPhotoDimensions = CMVideoDimensions()
            photoOutput.maxPhotoQualityPrioritization = .quality
        } else {
            print("output session에서 촬영 장치를 추가하지 못했습니다.")
            setupResult = .configurationFaild
            session.commitConfiguration()
            return
        }
        
        
        
        session.commitConfiguration()
        isConfigured = true
        //self.start()
    }
    
}

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
    
}
