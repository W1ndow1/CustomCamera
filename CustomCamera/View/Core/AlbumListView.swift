//
//  AlbumsView.swift
//  CustomCamera
//
//  Created by window1 on 6/21/24.
//

import SwiftUI
import PhotosUI

struct AlbumListView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = PhotoLibrary()
    var body: some View {
        NavigationStack {
            List {
                if let allPhotos = viewModel.allPhotos.firstObject {
                    Section(header: Text(AlbumSectionType.all.description)){
                        NavigationLink(destination: PhotoGridView(model: PhotoGridViewModel(assets: viewModel.allPhotos))) {
                            AlbumTitleView(title: AlbumSectionType.all.description, count: viewModel.allPhotos.count, asset: allPhotos, model: viewModel)
                        }
                    }
                }
                albumSection(for: viewModel.smartAlbums, title: AlbumSectionType.smartAlbums.description)
                albumSection(for: viewModel.userCollections, title: AlbumSectionType.userCollections.description)
            }
            .navigationTitle("사진보관함")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button{
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .imageScale(.large)
                            .foregroundStyle(.foreground)
                    }
                }
            }
            .onAppear(){
                Task {
                    await viewModel.checkPermissionAndFetchAssets()
                }
            }
            
        }
    }
    @ViewBuilder
    private func albumSection(for fetchResult: PHFetchResult<PHAssetCollection>, title: String) -> some View {
        Section(header: Text(title)) {
            ForEach(0..<fetchResult.count, id: \.self) { index in
                let assetCollection = fetchResult.object(at: index)
                let assets = PHAsset.fetchAssets(in: assetCollection, options: nil)
                if let firstAsset = assets.firstObject {
                    NavigationLink(destination: PhotoGridView(model: PhotoGridViewModel(assets: assets))) {
                        AlbumTitleView(title: assetCollection.localizedTitle ?? "이름 없는 앨범", count: assets.count, asset: firstAsset, model: viewModel)
                    }
                } else {
                    Text(assetCollection.localizedTitle ?? "이름 없는 앨범")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    AlbumListView()
}

extension AlbumListView {
    var albumView: some View {
        VStack(alignment: .leading){
            Text("123")
        }
    }
}
