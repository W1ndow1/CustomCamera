//
//  ContentView.swift
//  CustomCamera
//
//  Created by window1 on 3/29/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject var model = CameraModel()
    @State var currentZoomFactor: CGFloat = 1.0
    @State var animationValue = 0.5
    
    var captureButton: some View {
        Button(action: {
            model.capturePhoto()
        }, label: {
            Circle()
                .foregroundStyle(.white)
                .frame(width: 70, height: 70)
                .overlay(content: {
                    Circle()
                        .stroke(Color.black.opacity(0.8), lineWidth: 2)
                        .frame(width: 65, height: 65, alignment: .center)
                })
        })
    }
    
    var capturedPhotoThumbnail: some View {
        Group {
            if model.photo != nil {
                Image(uiImage: model.photo.image!)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .animation(.spring(), value: animationValue)
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white, lineWidth: 1)
                    .frame(width: 60, height: 60, alignment: .center)
                    .foregroundStyle(.black)
            }
        }
    }
    var filpCameraButton: some View {
        Button(action: {
            model.flipCamera()
        }, label: {
            Circle()
                .foregroundStyle(.gray.opacity(0.2))
                .frame(width: 45, height: 45, alignment: .center)
                .overlay(content: {
                    Image(systemName: "camera.rotate.fill")
                        .foregroundStyle(.white)
                })
        })
    }
    
    var body: some View {
        GeometryReader { reader in
            ZStack {
                Color.black.ignoresSafeArea(.all)
                VStack {
                    Button(action: {
                        model.switchFlash()
                    }, label: {
                        Image(systemName: model.isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                            .font(.system(size: 20, weight: .medium, design: .default))
                    })
                    .foregroundStyle(model.isFlashOn ? .yellow : .white)
                    
                    CameraPreview(session: model.session)
                        .gesture(
                            DragGesture().onChanged({ drag in
                                if abs(drag.translation.height) > abs(drag.translation.width) {
                                    let percentage: CGFloat = -(drag.translation.height / reader.size.height)
                                    let calc = currentZoomFactor + percentage
                                    let zoomFactor: CGFloat = min(max(calc, 1), 5)
                                    currentZoomFactor = zoomFactor
                                    model.zoom(with: zoomFactor)
                                }
                            })
                        )
                        .onAppear {
                            model.configure()
                        }
                        .alert(isPresented: $model.showAlertError, content: {
                            Alert(title: Text(model.alertError.title), message: Text(model.alertError.message), dismissButton: .default(Text(model.alertError.primaryButtonTitle), action: { model.alertError.primaryAction?()
                            }))
                        })
                        .overlay(
                            Group{
                                if model.willCapturePhoto{
                                    Color.black
                                }
                            }
                        )
                        .animation(.easeInOut, value: 0.5)
                    
                    HStack{
                        capturedPhotoThumbnail
                        Spacer()
                        captureButton
                        Spacer()
                        filpCameraButton
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
}


#Preview {
    ContentView()
}
