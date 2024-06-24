//
//  PhotoLibraryView.swift
//  CustomCamera
//
//  Created by window1 on 6/14/24.
//

import SwiftUI
import PhotosUI

struct PhotoLibraryView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.displayScale) var scale
    @ObservedObject var viewModel = PhotoLibrary()
    
    private let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 4)
    
    var body: some View {
        NavigationStack {
            if viewModel.isAuthorized {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVGrid(columns: gridColumns, spacing: 2) {
                            ForEach(viewModel.photos.indices, id: \.self) { index in
                                let asset = viewModel.photos[index]
                                NavigationLink(destination: PhotoDetailView(viewModel: viewModel, asset: asset)) {
                                    AssetImageView(viewModel: viewModel, asset: asset)
                                        .id(index)
                                }
                            }
                        }
                    
                        .onAppear {
                            DispatchQueue.main.async {
                                if let lastIndex = viewModel.photos.indices.last {
                                    proxy.scrollTo(lastIndex, anchor: .bottom)
                                }
                            }
                        }
                    }
                    .navigationTitle("라이브러리")
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
                    .onAppear {
                        viewModel.scale = self.scale
                    }
                }
            } else {
                Text("사진 보관한 접근을 위한 권한이 필요합니다.")
                    .onAppear {
                        viewModel.checkPhotoLibarayAuthorization()
                    }
            }
        }
        
    }
}


#Preview {
    PhotoLibraryView()
}


struct AssetImageView: View {
    @ObservedObject var viewModel: PhotoLibrary
    let asset: PHAsset
    
    @State private var image: UIImage? = nil
    
    var body: some View {
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(1, contentMode: .fill)
            } else {
                Color.clear
                    .frame(width: 100, height: 100)
                    .onAppear() {
                        DispatchQueue.main.async {
                            viewModel.requestImage(for: asset, targetSize: CGSize(width: 50, height: 50)) { fetchImage in
                                self.image = fetchImage
                            }
                        }
                    }
            }
        }
    }
}


