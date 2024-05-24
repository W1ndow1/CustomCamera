

import SwiftUI
import PhotosUI

struct ContentView: View {
    @StateObject var simpleModel = CameraViewModel()
    @State var zoomValue: String = "0.0"
    var degToFaceUp: Double
    
    var body: some View {
        ZStack {
            if #available(iOS 17.0, *) {
                simpleModel.cameraPreview.ignoresSafeArea()
                    .onAppear() {
                        simpleModel.configure()
                    }
                    .onDisappear() {
                        
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
                    WaterMarkView()
                        .viewRotationEffect(deg: degToFaceUp)
                }
                
                Spacer()
                Text(zoomValue)
                    .foregroundStyle(.yellow)
                    .viewRotationEffect(deg: degToFaceUp)
                LensChangeView()
                    .overlay {
                        HStack(spacing: 25) {
                            LensChangeView().ultraWideAngleLens
                                .viewRotationEffect(deg: degToFaceUp)
                            LensChangeView().wideLens
                                .viewRotationEffect(deg: degToFaceUp)
                            LensChangeView().telescopeLens
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


#Preview {
    ContentView(degToFaceUp: 0)
}

extension ContentView {
    
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
            simpleModel.waterMarkImage = simpleModel.isWaterMarkOn ? viewToImage(view: WaterMarkView()) : nil
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
        PhotosPicker(selection: $simpleModel.imageSelection, matching: .images, photoLibrary: .shared()) {
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
