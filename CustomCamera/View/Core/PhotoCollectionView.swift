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
    
    private static let itemSpacing = 12.0
    private static let itemSize = CGSize(width: 90, height: 90)
    
    private var imageSize: CGSize {
        return CGSize(width: Self.itemSize.width * min(displayScale, 2), height: Self.itemSize.height * min(displayScale, 2))
    }
    
    private let colums = [GridItem(.adaptive(minimum: itemSize.width, maximum: itemSize.height), spacing: 2)]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: colums, spacing: 2) {
                    ForEach(photoCollection.photoAssets) { asset in
                        NavigationLink {
                            PhotoView(asset: asset, cache: photoCollection.cache)
                        } label: {
                            photoItemView(asset: asset)
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel(asset.accessibilityLabel)
                    }
                }
            }
            .navigationTitle("포토라이브러리")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button{
                        dismiss()
                    } label: {
                        Image(systemName: "camera")
                            .imageScale(.large)
                            .foregroundStyle(.foreground)
                    }
                }
            }
        }
    }
    
    private func photoItemView(asset: PhotoAsset) -> some View {
        PhotoItemView(asset: asset, cache: photoCollection.cache, imageSize: imageSize)
            .frame(width: Self.itemSize.width, height: Self.itemSize.height)
            .clipShape(Rectangle())
            .overlay(alignment: .bottomLeading) {
                if asset.isFavorite {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.white)
                        .font(.callout)
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
