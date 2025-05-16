//
//  PhotoView.swift
//  CustomCamera
//
//  Created by window1 on 7/3/24.
//

import SwiftUI
import Photos

struct PhotoView: View {
   
    @Environment(\.dismiss) var dismiss
    
    @State var asset: PhotoAsset
    var cache: CachedImageManager?
    var photoCollection: PhotoCollection?
    
    @State private var offset = CGSize.zero
    @State private var image: Image?
    @State private var imageRequestID: PHImageRequestID?
    @GestureState var dragPosition = CGSize.zero
    
    private let imageSize = CGSize(width: 1024, height: 1024)
    
    var body: some View {
        Group {
            if let image = image {
                image
                    .resizable()
                    .scaledToFit()
                    .accessibilityLabel(asset.accessibilityLabel)
            }
            else {
                ProgressView()
            }
        }
        .offset(dragPosition)
        .gesture(
            DragGesture()
                .updating($dragPosition, body: { value, state, transaction in
                    state.width = value.translation.width
                }))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .navigationTitle(itemCount())
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard image == nil, let cache = cache else { return }
            imageRequestID = await cache.requestImage(for: asset, targetSize: imageSize) { result in
                Task {
                    if let result = result {
                        self.image = result.image
                    }
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                Button {
                    Task {
                        await asset.delete()
                        updateAsset()
                    }
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.blue)
                        .font(.system(size: 15))
                }
                Spacer()
                Button {
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
    private func updateAsset() {
        if let oldAssetIndex = asset.index {
            let newAssetIndex = oldAssetIndex - 1
            self.asset = photoCollection?.photoAssets[newAssetIndex] ?? .init(identifier: "")
            Task {
                imageRequestID = await cache?.requestImage(for: asset, targetSize: imageSize) { result in
                    if let result = result {
                        self.image = result.image
                    }
                }
            }
        }
    }
}

#Preview {
    PhotoView(asset: .init(phAsset: .init(), index: 1))
}

extension PhotoView {
    var swipeToChangePicture: some Gesture {
        DragGesture()
            .onChanged { gesture in
                withAnimation() {
                    offset = gesture.translation
                }
            }
            .onEnded { gesture in
                withAnimation() {
                    offset = .zero
                }
            }
    }

    func itemCount() -> String{
        let allphotos = photoCollection?.photoAssets.count ?? 0
        let photoIndex = asset.index ?? 0
        return "\(String(photoIndex))/\(String(allphotos))"
    }
}
