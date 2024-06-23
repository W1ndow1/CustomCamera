//
//  PhotoDetailView.swift
//  CustomCamera
//
//  Created by window1 on 6/18/24.
//

import SwiftUI
import Photos

struct PhotoDetailView: View {
    @ObservedObject var viewModel: PhotoLibrary
    var asset: PHAsset
    @State private var image: UIImage? = nil
    @State private var isControllerHidden = false
    
    var body: some View {
            ZStack {
                isControllerHidden ? Color.black.ignoresSafeArea() : Color.clear.ignoresSafeArea()
                
                VStack {
                    if let image = image {
                        Spacer()
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                        Spacer()
                    } else {
                        Rectangle()
                            .foregroundStyle(Color.green)
                            .onAppear() {
                                viewModel.requestImage(for: asset,
                                                       targetSize: PHImageManagerMaximumSize,
                                                       completion: { fetchedImage in
                                    self.image = fetchedImage
                                })
                            }
                    }
                }
                .onTapGesture {
                        isControllerHidden.toggle()
                }
                .toolbar {
                    if !isControllerHidden {
                        ToolbarItemGroup(placement:.bottomBar) {
                            Button(action: {
                                print("사진삭제")
                            }) {
                                Image(systemName: "trash")
                                    .foregroundStyle(.blue)
                                    .font(.system(size: 15))
                                
                            }
                            Spacer()
                            Button(action: {
                                print("즐겨찾기 등록")
                            }) {
                                Image(systemName: "heart")
                                    .foregroundStyle(.blue)
                                    .font(.system(size: 15))
                                
                            }
                        }
                    }
                }
            }
            .toolbar(isControllerHidden ? .hidden: .visible)
            .ignoresSafeArea()
    }
}

#Preview {
    PhotoDetailView(viewModel: .init(), asset: .init())
}
