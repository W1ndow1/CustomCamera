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
    var photoAssets: PhotoAssetCollection?
    
    @Environment(\.dismiss) var dismiss
    
    @State private var image: Image?
    @State private var imageRequestID: PHImageRequestID?
    @State private var offset = CGSize.zero
    
    var body: some View {
        Group {
            if let image = image {
                image
                    .resizable()
                    .scaledToFit()
                    .accessibilityLabel(asset.accessibilityLabel)
                    .offset(offset)
                    .gesture(swipeToChangePicture)
            }
            else {
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .navigationTitle(itemCount())
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
    
    func checkIsDismissable(gesture: _ChangedGesture<DragGesture>.Value) -> Bool {
        let dismissalbeLocatioin = gesture.translation.height > 50
        let dismissableVelocity = gesture.velocity.height > 50
        return dismissalbeLocatioin || dismissableVelocity
    }

    func itemCount() -> String{
        let allphotos = photoAssets?.count ?? 0
        let index = asset.index ?? 0
        return "\(String(allphotos))/\(String(index + 1))"
    }
}
