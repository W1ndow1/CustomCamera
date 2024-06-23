//
//  AlbumTitleView.swift
//  CustomCamera
//
//  Created by window1 on 6/22/24.
//

import SwiftUI
import Photos

struct AlbumTitleView: View {
    let title: String
    let count : Int
    let asset: PHAsset

    @ObservedObject var model: PhotoLibrary
    @State private var image: UIImage? = nil
    
    var body: some View {
        VStack(alignment:.leading) {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            } else {
                Image("bobcat")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }
            Text(title)
                .font(.system(size: 20, weight: .regular))
            Text("\(count)")
                .font(.system(size: 15, weight: .light))
        }
        .onAppear() {
            DispatchQueue.main.async {
                model.loadAssetImage(for: asset, targetSize: CGSize(width: 200, height: 200)) { titleImage in
                    self.image = titleImage
                }
                
            }
        }
    }
}

#Preview {
    AlbumTitleView(title: "전체사진", count: 9999, asset: .init(), model: PhotoLibrary())
}
