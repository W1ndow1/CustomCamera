//
//  PhotoGalleryView.swift
//  CustomCamera
//
//  Created by window1 on 7/17/24.
//

import SwiftUI
import Photos

struct PhotoGalleryView: View {
    @ObservedObject var photoCollection: PhotoCollection
    @Environment(\.displayScale) private var displayScale
    
    @State private var image: Image?
    @State private var imageRequestID: PHImageRequestID?
    
    var colums = Array(repeating: GridItem(.flexible(minimum: 100, maximum: 300), spacing: 2), count: 4)
    
    private static let itemSize = CGSize(width: 90, height: 90)
    
    private var imageSize: CGSize {
        return CGSize(width: Self.itemSize.width * min(displayScale, 2), height: Self.itemSize.height * min(displayScale, 2))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                LazyVGrid(columns: colums, spacing: 2) {
                    ForEach(photoCollection.photoAssets) { asset in
                        NavigationLink{
                            
                        } label: {
                            photoItemView(asset: asset)
                        }
                    }
                }
                .padding(2)
            }
            .navigationTitle("최근사진")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    @ViewBuilder
    private func photoItemView(asset: PhotoAsset) -> some View {
        Group {
            if let image = image {
                image
                    .resizable()
                    .scaledToFill()
            } else {
                ProgressView()
                    .scaleEffect(0.5)
            }
        }
        .task {
            guard image == nil else { return }
            imageRequestID = await photoCollection.cache.requestImage(for: asset, targetSize: imageSize) { result in
                Task {
                    if let result = result {
                        self.image = result.image
                    }
                }
            }
        }
        .frame(width: Self.itemSize.width, height: Self.itemSize.height)
        .clipped()
        .overlay(alignment: .bottomLeading) {
            if asset.isFavorite {
                Image(systemName: "heart.fill")
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 1)
                    .font(.callout)
                    .offset(x: 4, y: -4)
            }
        }
        .onAppear {
            Task {
                await photoCollection.cache.startCaching(for: [asset], targetSize: imageSize)
            }
        }
        .onDisappear {
            Task {
                await photoCollection.cache.stopCaching(for: [asset], targetSize: imageSize)
            }
        }
    }
}


