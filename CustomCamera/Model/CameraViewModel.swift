
import Foundation
import AVFoundation
import SwiftUI
import Combine
import PhotosUI

class CameraViewModel: ObservableObject {
    
    private let model: Camera
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
    @Published var waterMarkText = "Window1"
    
    func switchWaterMark() {
        isWaterMarkOn.toggle()
    }

    func configure() {
        model.requestAndCheckPermission()
    }
    
    func switchFlash() {
        isFlashedOn.toggle()
        model.flashMode = isFlashedOn == true ? .on : .off
    }
    
    func switchSilent() {
        isSilentModeOn.toggle()
        model.isSilentModeOn = isSilentModeOn
    }
    
    func switchLivePhoto() {
        isLivePhotoOn.toggle()
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
            model.capturePhoto()
            
        } else {
            print("Camera is Busy")
        }
    }
    
    func flipCamera() {
        model.changeCamera()
    }
    
    func zoom(factor: CGFloat) {
        let delta = factor / lastZoomValue
        lastZoomValue = factor
        
        let newScale = min(max(currentZoomValue * delta, 1), 5)
        model.zoom(newScale)
        currentZoomValue = newScale
    }
    
    func zoomInitialize() {
        lastZoomValue = 1.0
    }
    
    func sendWaterMarkImage(mark: UIImage) {
        model.waterMarkReceive(image: mark)
    }
    
    init() {
        self.model = Camera()
        session = model.session
        cameraPreview = AnyView(CameraPreview(session: session))
        
        model.$recentIamge.sink { [weak self] capturePhoto in
            guard let pic = capturePhoto else { return }
            self?.recentImage = pic
        }
        .store(in: &self.subscriptions)
        
        model.$isCameraBusy.sink { [weak self] result in
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

class Camera: NSObject, ObservableObject {
    
    var session = AVCaptureSession()
    var videoDeviceInput: AVCaptureDeviceInput!
    let output = AVCapturePhotoOutput()
    var photoData = Data(count: 0)
    var isSilentModeOn = false
    var flashMode: AVCaptureDevice.FlashMode = .off
    var waterMark: UIImage?
    
    @Published var recentIamge: UIImage?
    @Published var isCameraBusy = false
    
    func waterMarkReceive(image: UIImage?) {
        self.waterMark = image
    }
    
    
    func setupCamera() {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else { return }
        do {
            videoDeviceInput = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
            }
        } catch {
            print(error.localizedDescription)
        }
        if session.canAddOutput(output) {
            session.addOutput(output)
            output.isLivePhotoCaptureEnabled = output.isLivePhotoCaptureSupported
            output.maxPhotoQualityPrioritization = .quality
            self.configurePhotoOutput()
        }
        session.startRunning()
    }
    
    func configurePhotoOutput()  {
        let supportedMaxPhotoDimensions = self.videoDeviceInput.device.activeFormat.supportedMaxPhotoDimensions
        let largestDimension = supportedMaxPhotoDimensions.last
        self.output.maxPhotoDimensions = largestDimension!
        self.output.isLivePhotoCaptureEnabled = self.output.isLivePhotoCaptureSupported
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
        let photoSettings = AVCapturePhotoSettings()
        photoSettings.flashMode = self.flashMode
        self.output.capturePhoto(with: photoSettings, delegate: self)

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
    
    func changeCamera() {
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
                
                //Sesssion에서 기존 장차정보 정보 지우기
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
                
                if let connection = self.output.connection(with: .video) {
                    session.sessionPreset = .high
                    if connection.isVideoStabilizationSupported {
                        connection.preferredVideoStabilizationMode = .auto
                    }
                }
                output.maxPhotoQualityPrioritization = .quality
                self.session.commitConfiguration()
                
            } catch {
                print("Error occurred: \(error)")
            }
        }
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
        self.recentIamge = UIImage(data: imageData)
        self.savePhoto(imageData)
        self.isCameraBusy = false
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
}
