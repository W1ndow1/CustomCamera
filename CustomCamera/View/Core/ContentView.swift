

import SwiftUI
import PhotosUI

struct ContentView: View {
    @StateObject var simpleModel = CameraViewModel()
    @State var zoomValue: String = "0.0"
    @State var showFocusIndicator = false
    @State var focustPoint: CGPoint? = nil
    @State var focusIndicatorColor: Color = .yellow
    @State var viewImage: UIImage?
    @State var isImageSeleted = false
    @Environment(\.displayScale) var displayScale
    var degToFaceUp: Double
    
    var body: some View {
        NavigationStack {
            ZStack {
                if #available(iOS 17.0, *) {
                    simpleModel.cameraPreview.ignoresSafeArea()
                        .onAppear() {
                            simpleModel.configure()
                        }
                        .onDisappear() {
                            simpleModel.stopSession()
                        }
                        .gesture(MagnifyGesture()
                            .onChanged { val in
                                simpleModel.zoom(factor: val.magnification)
                                zoomValue = String(describing: round(val.magnification))
                                
                            }
                            .onEnded { _ in
                                simpleModel.zoomInitialize()
                            }
                        )
                        .onTapGesture { location in
                            //포인터 정보 전달
                            let screenSize = UIScreen.main.bounds.size
                            let focusPoint = CGPoint(x: location.x / screenSize.width, y: location.y / screenSize.height)
                            simpleModel.focusAndExposeTap(focusPoint)
                            //화면에 포인터 표시
                            self.focustPoint = location
                            self.showFocusIndicator = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                self.showFocusIndicator = false
                            }
                        }
                } else {
                    simpleModel.cameraPreview.ignoresSafeArea()
                        .onAppear() {
                            simpleModel.configure()
                        }
                        .onDisappear() {
                            
                        }
                        .gesture(MagnificationGesture()
                            .onChanged { value in
                                simpleModel.zoom(factor: value)
                            }
                            .onEnded { _ in
                                simpleModel.zoomInitialize()
                            }
                        )
                }
                if let focustPoint = focustPoint, showFocusIndicator {
                    focusIndicatorButton
                        .position(focustPoint)
                        .transition(.opacity)
                }
                VStack {
                    HStack(spacing: 70){
                        silentShutterButton
                        livePhotoButton
                        waterMarkButton
                        flashButton
                    }
                    .padding(.vertical, 20)
                    Spacer()
                    
                    if simpleModel.isWaterMarkOn {
                        WaterMarkView(model: simpleModel)
                            .viewRotationEffect(deg: degToFaceUp)
                    }
                    
                    Spacer()
                    Text(zoomValue)
                        .foregroundStyle(.yellow)
                        .viewRotationEffect(deg: degToFaceUp)
                    LensChangeView(model: simpleModel)
                        .overlay {
                            HStack(spacing: 25) {
                                LensChangeView(model: simpleModel).ultraWideAngleLens
                                    .viewRotationEffect(deg: degToFaceUp)
                                LensChangeView(model: simpleModel).wideLens
                                    .viewRotationEffect(deg: degToFaceUp)
                                LensChangeView(model: simpleModel).telescopeLens
                                    .viewRotationEffect(deg: degToFaceUp)
                            }
                        }
                    HStack {
                        capturedPhotoThumbnail
                        Spacer()
                        captureButton
                        Spacer()
                        flipCameraButton
                    }
                    .padding(.horizontal, 20)
                }
                
            }
            .opacity(simpleModel.shutterEffect ? 0 : 1)
        }
    }
}


#Preview {
    ContentView(degToFaceUp: 0)
}

extension ContentView {
    
    var viewImageView: some View {
        if viewImage != nil {
            Image(uiImage: viewImage ?? UIImage())
        } else {
            Image(systemName: "circle")
        }
    }
    
    var focusIndicatorButton: some View {
        Button(action: {}, label: {
            Image(systemName: "circle.circle")
                .font(.system(size: 60, weight: .medium))
        })
        .foregroundStyle(focusIndicatorColor)
    }
    
    
    var waterMarkButton: some View {
        Button(action: {
            simpleModel.switchWaterMark()
        }, label: {
            Image(systemName: simpleModel.isWaterMarkOn ? "bookmark.fill" : "bookmark.slash.fill")
                .viewRotationEffect(deg: degToFaceUp)
                .font(.system(size: 20, weight: .medium, design: .default))
                .frame(width: 40)
        })
        .foregroundStyle(simpleModel.isWaterMarkOn ? .yellow : .white)
    }
    
    
    var livePhotoButton: some View {
        Button(action: {
            simpleModel.switchLivePhoto()
        }, label: {
            Image(systemName: simpleModel.isLivePhotoOn ? "livephoto": "livephoto.slash")
                .viewRotationEffect(deg: degToFaceUp)
                .font(.system(size: 20, weight: .medium, design: .default))
                .frame(width: 40)
        })
        .foregroundStyle(simpleModel.isLivePhotoOn ? .yellow : .white)
    }
    
    var silentShutterButton: some View {
        Button {
            simpleModel.switchSilent()
        }label: {
            Image(systemName: simpleModel.isSilentModeOn ? "speaker.slash.fill" : "speaker.fill")
                .viewRotationEffect(deg: degToFaceUp)
                .font(.system(size: 20, weight: .medium, design: .default))
                .frame(width: 40)
        }
        .foregroundStyle(simpleModel.isSilentModeOn ? .yellow : .white)
    }
    
    var flashButton: some View {
        Button {
            simpleModel.switchFlash()
        } label: {
            Image(systemName: simpleModel.isFlashedOn ? "bolt.fill" : "bolt.slash.fill")
                .viewRotationEffect(deg: degToFaceUp)
                .font(.system(size: 20, weight: .medium, design: .default))
                .frame(width: 40)
        }
        .foregroundStyle(simpleModel.isFlashedOn ? .yellow : .white)
        
    }
    
    var captureButton: some View {
        Button(action: {
            simpleModel.capturePhoto()
            
            //이미지가 반으로 짤리는 현상
            //simpleModel.waterMarkImage = simpleModel.isWaterMarkOn ? WaterMarkView(model: simpleModel).snapshot() : nil
            
            let image = ImageRenderer(content: WaterMarkView(model: simpleModel))
            image.scale = displayScale
            
            simpleModel.waterMarkImage = simpleModel.isWaterMarkOn ? image.uiImage : nil
             
        }, label: {
            Circle()
                .foregroundStyle(.white)
                .frame(width: 70, height: 70)
                .overlay(content: {
                    Circle()
                        .stroke(Color.black.opacity(0.2), lineWidth: 2)
                        .frame(width: 65, height: 65, alignment: .center)
                })
        })
        .viewRotationEffect(deg: degToFaceUp)
    }
    
    var capturedPhotoThumbnail: some View {
        Button{
            print("포토라이브러리로 이동")
            isImageSeleted = true
        } label: {
            if let previewImage = simpleModel.recentImage {
                Image(uiImage: previewImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .animation(.spring(), value: 0.5)
            } else {
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.white, lineWidth: 1)
                    .frame(width: 60, height: 60, alignment: .center)
                    .foregroundStyle(.black)
            }
        }
        .viewRotationEffect(deg: degToFaceUp)
        .fullScreenCover(isPresented: $isImageSeleted) {
            PhotoLibraryView()
        }
    }

    var flipCameraButton: some View {
        Button(action: {
            simpleModel.flipCamera()
        }, label: {
            Circle()
                .foregroundStyle(.black.opacity(0.2))
                .frame(width: 60, height: 60, alignment: .center)
                .overlay(content: {
                    Image(systemName: "camera.rotate.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.white)
                        .frame(width: 33)
                    
                })
        })
        .viewRotationEffect(deg: degToFaceUp)
        .disabled(simpleModel.shutterEffect)
    }
}
