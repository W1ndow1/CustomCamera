//
//  CameraView.swift
//  CustomCamera
//
//  Created by window1 on 7/6/24.
//

import SwiftUI

struct CameraView: View {
    @StateObject private var model = DataModel()
    @State private var isThumbnailImageSeleted = false
    
    var body: some View {
        GeometryReader { geo in
            ViewFinderView(image: $model.viewfinderImage)
                .ignoresSafeArea()
                .overlay(alignment: .bottom) {
                    VStack(spacing: 20) {
                        LensSwitchButtonView()
                        ButtonView()
                    }
                }
        }
        .onAppear {
            model.photoCollection.selectedIndex = nil
        }
        .task {
            await model.cameraService.start()
            await model.loadPhotos()
            await model.loadThumbnail()
            
        }
    }
}

#Preview {
    CameraView()
}
extension CameraView {
    func ButtonView() -> some View {
        HStack(spacing: 80) {
            Button {
                isThumbnailImageSeleted = true
            } label : {
                if let image = model.thumbnailImage {
                    image
                        .resizable()
                        .scaledToFill()
                }
                else {
                    Image(systemName: "photo")
                        .foregroundStyle(.white)
                        .font(.system(size: 30))
                }
            }
            .frame(width: 41, height: 41)
            .clipShape(RoundedRectangle(cornerRadius: 11))
            .fullScreenCover(isPresented: $isThumbnailImageSeleted) {
                PhotoCollectionView(photoCollection: model.photoCollection)
                //PhotoGalleryView(photoCollection: model.photoCollection)
                    .onAppear {
                        model.cameraService.isPreviewPaused = true
                    }
                    .onDisappear {
                        model.cameraService.isPreviewPaused = false
                    }
            }
            Button {
                model.cameraService.takePhoto()
            } label: {
                ZStack {
                    Circle()
                        .stroke(.white, lineWidth: 3)
                        .frame(width: 55, height: 55)
                        .foregroundStyle(.white)
                    Circle()
                        .fill(.white)
                        .frame(width: 50, height: 50)
                }
                
            }
            
            Button {
                model.cameraService.switchCaptureDevice()
            } label: {
                Image(systemName: "arrow.triangle.2.circlepath.camera")
                    .font(.system(size: 30))
                    .foregroundStyle(.white)
            }
        }
    }
    
    func LensSwitchButtonView() -> some View {
        ZStack {
            Capsule()
                .frame(width: 210, height: 60)
                .foregroundStyle(.gray.opacity(0.2))
                .overlay {
                    HStack(spacing: 25) {
                        Button {
                            model.cameraService.switchBackCaptureDevice(lens: .builtInUltraWideCamera)
                        } label: {
                            Circle()
                                .frame(width: 50)
                                .foregroundStyle(.black.opacity(0.5))
                                .overlay {
                                    Text("0.5x")
                                        .foregroundStyle(.white)
                                }
                        }
                        Button {
                            model.cameraService.switchBackCaptureDevice(lens: .builtInWideAngleCamera)
                        } label: {
                            Circle()
                                .frame(width: 50)
                                .foregroundStyle(.black.opacity(0.5))
                                .overlay {
                                    Text("1.0x")
                                        .foregroundStyle(.white)
                                }
                        }
                        Button {
                            model.cameraService.switchBackCaptureDevice(lens: .builtInTelephotoCamera)
                        } label: {
                            Circle()
                                .frame(width: 50)
                                .foregroundStyle(.black.opacity(0.5))
                                .overlay {
                                    Text("2.0x")
                                        .foregroundStyle(.white)
                                }
                        }
                    }
                }
        }
    }
}
