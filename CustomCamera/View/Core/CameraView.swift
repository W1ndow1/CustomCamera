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
                    buttonView()
                }
        }
        .task {
            await model.loadPhotos()
        }
    }
}

#Preview {
    CameraView()
}
extension CameraView {
    func buttonView() -> some View {
        HStack(spacing: 80) {
            Button {
                isThumbnailImageSeleted = true
            } label : {
                Image(systemName: "photo")
                    .font(.system(size: 30))
                    .foregroundStyle(.white)
                    .border(.black)
            }
            .fullScreenCover(isPresented: $isThumbnailImageSeleted) {
                PhotoCollectionView(photoCollection: model.photoCollection)
                
            }
            
            Button {
                print("Take Photo")
            } label: {
                Circle()
                    .stroke(.yellow, lineWidth: 3)
                    .frame(width: 60, height: 60)
                    .foregroundStyle(.white)
                
            }
            
            Button {
                print("Flip Camera")
            } label: {
                Image(systemName: "arrow.triangle.2.circlepath.camera")
                    .font(.system(size: 30))
                    .foregroundStyle(.white)
            }
        }
    }
}
