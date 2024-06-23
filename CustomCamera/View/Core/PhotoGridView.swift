//
//  PhotoListView.swift
//  CustomCamera
//
//  Created by window1 on 6/22/24.
//

import SwiftUI
import PhotosUI

struct PhotoGridView: View {
    @ObservedObject var model: PhotoGridViewModel
    
    private let gridColumn = Array(repeating: GridItem(.flexible(), spacing: 2), count: 2)
    
    var body: some View {
        ScrollViewReader{ proxy in
            ScrollView {
                LazyVGrid(columns: gridColumn, spacing: 2){
                    ForEach(model.assets.objects(at: IndexSet(integersIn: 0..<model.assets.count)), id: \.self) { asset in
                        PhotoGridCellView(asset: asset)
                    }
                }
            }
        }
    }
}

#Preview {
    PhotoGridView(model: PhotoGridViewModel(assets: PHFetchResult<PHAsset>()))
}

