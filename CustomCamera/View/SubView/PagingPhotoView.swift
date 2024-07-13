//
//  PhotoView_Horizontal.swift
//  CustomCamera
//
//  Created by window1 on 7/11/24.
//

import SwiftUI
import Photos

struct PagingPhotoView: View {
    
    let imageNames = ["bobcat", "bullElk", "bullElkSparring", "bullTuleElkAndTwoFemales", "coyoteAndBison", "doubleRainbowLowerMammoth" ,"doubleRainbowYellowstone"
    ]
    var asset: PhotoAsset
    var cache: CachedImageManager?
    var photoCollection: PhotoCollection
    
    @State private var image: Image?
    @State private var imageRequestID: PHImageRequestID?
    
    
    var body: some View {
        VStack {
            ScrollViewReader { reader in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack {
                        ForEach(photoCollection.photoAssets.indices, id:\.self) { index in
                            photoItemView(asset: photoCollection.photoAssets[index])
                                .id(index)
                        }
                    }
                    .scrollTargetLayout()
                }
                .frame(height: 600)
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: .constant(100))
            }
            
            ScrollViewReader { reader in
                ScrollView(.horizontal) {
                    LazyHStack {
                        ForEach(imageNames, id: \.self) { imageName in
                            Image(imageName)
                                .resizable()
                                .scaledToFill()
                                .containerRelativeFrame(.horizontal) { size, axis in
                                    size * 0.09
                                }
                                .frame(height: 60)
                                .clipped()
                                .padding(.horizontal, -3)
                        }
                    }
                }
                .frame(height: 100)
                .scrollIndicators(.hidden)
            }
        }
    }
    
    private func photoItemView(asset: PhotoAsset) -> some View {
        PhotoView_Horizontal_ItemView(asset: asset, cache: cache)
            .containerRelativeFrame(.horizontal, count: 1, span: 1, spacing: 10)
            .clipped()
            .onAppear {
                Task {
                    await photoCollection.cache.startCaching(for:[asset], targetSize: CGSize(width: 1024, height: 1024))
                }
            }
            .onDisappear {
                Task {
                    await photoCollection.cache.stopCaching(for:[asset], targetSize: CGSize(width: 1024, height: 1024))
                }
            }
    }
}

#Preview {
    PagingPhotoView(asset: .init(identifier: ""), photoCollection: .init(albumNamed: ""))
}

struct PhotoView_Horizontal_ItemView: View {
    
    var asset: PhotoAsset
    var cache: CachedImageManager?
    
    @State private var image: Image?
    @State private var imageRequestID: PHImageRequestID?
    
    var body: some View {
        Group {
            if let image = image {
                image
                    .resizable()
                    .scaledToFit()
                    .clipped()
            } else {
                ProgressView()
            }
        }
        .task {
            guard image == nil, let cache = cache else { return }
            imageRequestID = await cache.requestImage(for: asset, targetSize: CGSize(width: 1024, height: 1024)) { result in
                Task{
                    if let result = result {
                        image = result.image
                    }
                }
            }
        }
    }
}
