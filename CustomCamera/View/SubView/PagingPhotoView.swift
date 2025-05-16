//
//  PhotoView_Horizontal.swift
//  CustomCamera
//
//  Created by window1 on 7/11/24.
//

import SwiftUI
import Photos

struct PagingPhotoView: View {
    
    @Environment(\.dismiss) var dismiss
    @State private var currentAssetIndex: Int?

    @ObservedObject var photoCollection: PhotoCollection
    @State var asset: PhotoAsset
    var cache: CachedImageManager
    
    
    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 10.0) {
                        ForEach(photoCollection.photoAssets.indices, id: \.self) { index in
                            photoItemView(asset: photoCollection.photoAssets[index], cache: cache)
                                .frame(width: UIScreen.main.bounds.width, height: 600)
                        }
                    }
                    .onAppear {
                        proxy.scrollTo(asset.index)
                        currentAssetIndex = asset.index
                    }
                    .scrollTargetLayout()
                  
                }
                .frame(width: UIScreen.main.bounds.width, height: 600)
                .scrollPosition(id: $currentAssetIndex)
                .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
                .safeAreaPadding(.horizontal, 20)
                .toolbar {
                    ToolbarItemGroup(placement: .bottomBar) {
                        Button {
                            //TODO: - 삭제 하고 나서 뷰 ScrollView reset 하기
                            Task {
                                if let currentAssetIndex = currentAssetIndex {
                                    await photoCollection.photoAssets[currentAssetIndex].delete()
                                }
                            }
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(.blue)
                                .font(.system(size: 15))
                        }
                        Spacer()
                        Button {
                            //TODO: - 인덱스에 맞게 동작하는지 확인해야함
                            Task {
                                await asset.setIsFavorite(!asset.isFavorite)
                            }
                        } label: {
                            Image(systemName: asset.isFavorite ? "heart.fill" : "heart")
                                .foregroundStyle(.blue)
                                .font(.system(size: 15))
                        }
                    }
                }
            }
        }
        .navigationTitle(itemCount())
    }
    
    func itemCount() -> String{
        let allphotos = photoCollection.photoAssets.count
        let photoIndex = currentAssetIndex
        return "\(String(photoIndex ?? 0))/\(String(allphotos))"
    }
    
    
    private func photoItemView(asset: PhotoAsset, cache: CachedImageManager) -> some View {
        PagingPhoto_ItemView(asset: asset, cache: cache)
            .onAppear {
                Task {
                    await photoCollection.cache.startCaching(for:[asset], targetSize: CGSize(width: 300, height: 300))
                }
            }
            .onDisappear {
                Task {
                    await photoCollection.cache.stopCaching(for:[asset], targetSize: CGSize(width: 300, height: 300))
                }
            }
    }
}


struct PagingPhoto_ItemView: View {
    
    @State var asset: PhotoAsset
    @State var cache: CachedImageManager?
    
    @State private var image: Image?
    @State private var imageRequestID: PHImageRequestID?
    
    var body: some View {
        Group {
            if let image = image {
                image
                    .resizable()
                    .scaledToFit()
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
