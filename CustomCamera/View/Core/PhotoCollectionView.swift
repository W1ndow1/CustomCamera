//
//  PhotoCollectionView.swift
//  CustomCamera
//
//  Created by window1 on 6/24/24.
//

import SwiftUI

struct PhotoCollectionView: View {
    
    @ObservedObject var photoCollection: PhotoCollection
    @Environment(\.displayScale) private var displayScale
    @Environment(\.dismiss) var dismiss
    @Namespace var bottomID
    
    private static let itemSize = CGSize(width: 123, height: 123)
    
    private var imageSize: CGSize {
        return CGSize(width: Self.itemSize.width * min(displayScale, 2), height: Self.itemSize.height * min(displayScale, 2))
    }
    
    private let colums = [GridItem(.adaptive(minimum: itemSize.width, maximum: itemSize.height), spacing: 2)]
    
    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVGrid(columns: colums, spacing: 2) {
                        ForEach(photoCollection.photoAssets) { asset in
                            NavigationLink {

//                                PhotoView(asset: asset,
//                                          cache: photoCollection.cache,
//                                          photoCollection: photoCollection)
                                 
                                
                                 PagingPhotoView(photoCollection: photoCollection,
                                 asset: asset,
                                 cache: photoCollection.cache)
                                 
                            } label : {
                                photoItemView(asset: asset)
                            }
                            .buttonStyle(.borderless)
                            .accessibilityLabel(asset.accessibilityLabel)
                        }
                    }
                }
                .defaultScrollAnchor(.bottom)
                .frame(maxHeight: UIScreen.main.bounds.height)
                .navigationTitle(photoCollection.albumName ?? "사진보관함")
                .navigationBarTitleDisplayMode(.inline)
                .statusBarHidden()
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button{
                            dismiss()
                            photoCollection.selectedIndex = nil
                        } label: {
                            Image(systemName: "camera")
                                .imageScale(.large)
                                .foregroundStyle(.foreground)
                        }
                    }
                }
            }
        }
    }
    @ViewBuilder
    private func photoItemView(asset: PhotoAsset) -> some View {
        PhotoItemView(asset: asset, cache: photoCollection.cache, imageSize: imageSize)
            .frame(width: Self.itemSize.width, height: Self.itemSize.height)
            .clipped()
            .overlay(alignment: .bottomLeading) {
                if asset.isFavorite {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.white)
                }
            }
            .onAppear {
                Task {
                    await photoCollection.cache.startCaching(for:[asset], targetSize: imageSize)
                }
            }
            .onDisappear {
                Task {
                    await photoCollection.cache.stopCaching(for:[asset], targetSize: imageSize)
                }
            }
    }
}

#Preview {
    PhotoCollectionView(photoCollection: .init(albumNamed: ""))
}
