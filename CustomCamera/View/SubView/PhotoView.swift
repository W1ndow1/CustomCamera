//
//  PhotoView.swift
//  CustomCamera
//
//  Created by window1 on 7/3/24.
//

import SwiftUI
import Photos

struct PhotoView: View {
    var asset: PhotoAsset
    var cache: CachedImageManager?
    @State var image: Image?
    @State var imageRequestID: PHImageRequestID?
    @Environment(\.dismiss) var dismiss
    
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .navigationTitle("사진")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard image == nil, let cache = cache else { return }
            imageRequestID = await cache.requestImage(for: asset, targetSize: CGSize(width: 1024, height: 1024)) { result in
                Task {
                    if let result = result {
                        image = result.image
                    }
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                Button {
                    Task {
                        await asset.delete()
                        await MainActor.run {
                            dismiss()
                        }
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
}

#Preview {
    PhotoView(asset: .init(phAsset: .init(), index: 1))
}
