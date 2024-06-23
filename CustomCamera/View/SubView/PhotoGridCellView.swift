//
//  PhotoGridCellView.swift
//  CustomCamera
//
//  Created by window1 on 6/23/24.
//

import SwiftUI
import Photos

struct PhotoGridCellView: View {
    
    let asset: PHAsset?
    
    @State private var image: UIImage?
    
    var body: some View {
        VStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipped()
                   
            } else {
                Rectangle()
                    .fill(Color.black.opacity(0.5))
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipped()
                    
            }
        }
        .onAppear() {
            //사진 로드하는 코드
            loadAssetImage(targetSzie: CGSize(width: 100, height: 100))
            
        }
    }
    
    func loadAssetImage(targetSzie: CGSize) {
        guard let asset else {
            self.image = UIImage(systemName: "photo")
            return
        }
        let options = PHImageRequestOptions()
        options.version = .original
        options.deliveryMode = .highQualityFormat
        options.isSynchronous = false
        options.isNetworkAccessAllowed = true
        PHImageManager.default().requestImage(for: asset, targetSize: targetSzie, contentMode: .aspectFit, options: options) { image, _ in
            if let image {
                self.image = image
            }
        }
    }
}

#Preview {
    PhotoGridCellView(asset: PHAsset())
}
